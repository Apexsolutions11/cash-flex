import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth, getRequestIpAddress } from '@/lib/middleware/auth';
import { db, admin } from '@/lib/firebase-admin';
import * as payment from '@/lib/helpers/wallet-helper/payment-helper';
import * as other from '@/lib/helpers/other-service';
import { getSettings } from '@/lib/helpers/settings-helper';

export async function POST(request: NextRequest) {
  try {
    const authContext = await verifyAuth(request);

    if (!authContext || !authContext.uid) {
      return NextResponse.json(
        {
          response: 'failure',
          reason: 'Access denied.',
        },
        { status: 401 },
      );
    }

    const ipAddress = getRequestIpAddress(request);
    const userId = authContext.uid.trim();
    const body = await request.json();
    const payoutId: string = body.id ? body.id : '';

    const userDoc = await db.collection('users').doc(userId).get();
    const userDocData = userDoc.data();

    if (!userDoc.exists || !userDocData) {
      return NextResponse.json({
        response: 'failure',
        reason: 'User account not found.',
      });
    }

    if (userDocData.walletBlocked) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Your wallet is currently blocked. Please contact support for further assistance.',
      });
    }

    const balance: number = userDocData.balance ?? 0;
    const dailyPayoutCount: number = userDocData.dailyPayoutCount ?? 0;
    const email = userDocData.email ?? '';
    const adjoeEarning: number = userDocData.adjoeEarning ?? 0;
    const fcmToken: string = userDocData.fcmToken ?? '';
    const deviceId: string = userDocData.deviceId ?? '';
    const verifiedUser: boolean = userDocData.verifiedUser ?? false;
    const country: string = userDocData.country ?? '';

    const settings = await getSettings();
    const serverData = await db.collection('admin').doc('serverData').get();
    const walletEnabled = serverData.data()?.walletEnabled ?? false;

    if (!walletEnabled && settings.adminEmail !== email) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Wallet is currently under maintenance. Please try again later.',
      });
    }

    // if (adjoeEarning < 1) {
    //   return NextResponse.json({
    //     response: 'failure',
    //     reason: 'Your wallet is locked. Please complete any task in Cash Games/Playtime to unlock it.',
    //   });
    // }

    if (!verifiedUser) {
      return NextResponse.json({
        response: 'failure',
        reason: "Profile not verified. Please go to 'Edit Profile' and fill in the required details to enable payments.",
      });
    }

    if (dailyPayoutCount >= settings.dailyMaxPayout) {
      return NextResponse.json({
        response: 'failure',
        reason: 'DAILY_LIMIT',
      });
    }

    const { method, amount } = payment.splitMethodAndAmount(payoutId);

    if (method === '' || amount === 0) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Invalid voucher data. Please check and try again.',
      });
    }

    const methodDetails = userDocData[method];

    if (!methodDetails) {
      return NextResponse.json({
        response: 'failure',
        reason: `Selected payment method's details not found in your account. Please add the required details.`,
      });
    }

    const duplicateDocs = await db
      .collection('users')
      .where(method, '==', methodDetails)
      .limit(5)
      .get();

    if (duplicateDocs.size > 4) {
      const batch = db.batch();
      duplicateDocs.docs.forEach(async (doc) => {
        await other.blockUserWallet(db, doc.id, 'MULTI_PAYEE_ACCOUNT');
      });

      await batch.commit();

      return NextResponse.json({
        response: 'failure',
        reason: 'Your wallet is currently blocked. Please contact us for further assistance.',
      });
    }

    const methodDocRef = db.collection('walletCatalog').doc(method);
    const methodDoc = await methodDocRef.get();
    const methodDocData = methodDoc.data();

    if (!methodDoc.exists || !methodDocData) {
      return NextResponse.json({
        response: 'failure',
        reason: `Selected payment method does not exist. Please select a valid method.`,
      });
    }

    if (!methodDocData.enabled) {
      return NextResponse.json({
        response: 'failure',
        reason: `Selected payment method is currently disabled. Please try again later.`,
      });
    }

    const symbol: string = methodDocData.symbol ? methodDocData.symbol : '';

    const methodDenominationRef = methodDocRef.collection('denominations').doc(payoutId);
    const methodDenominationDoc = await methodDenominationRef.get();
    const methodDenominationData = methodDenominationDoc.data();

    if (!methodDenominationDoc.exists || !methodDenominationData) {
      return NextResponse.json({
        response: 'failure',
        reason: 'The specified amount is invalid. Please select a valid amount.',
      });
    }

    if (!methodDenominationData.enabled) {
      return NextResponse.json({
        response: 'failure',
        reason: 'This voucher is currently locked for you. Please earn more coins to unlock it.',
      });
    }

    if (methodDenominationData.amount !== amount) {
      return NextResponse.json({
        response: 'failure',
        reason: 'The specified amount does not match our records. Please try again.',
      });
    }

    const coins: number = methodDenominationData.coins ? methodDenominationData.coins : 0;

    if (balance < coins) {
      return NextResponse.json({
        response: 'failure',
        reason: 'Insufficient balance. Please earn more coins to proceed.',
      });
    }

    const orderId = await other.genOrderID();

    const result = await payment.processPaymentRequest(
      method,
      methodDetails,
      amount,
      orderId,
      userId,
      ipAddress,
      fcmToken,
      coins,
      symbol,
      email,
      deviceId,
      country,
    );

    return NextResponse.json(result);
  } catch (error) {
    return NextResponse.json(
      {
        response: 'failure',
        reason: 'An error occurred while processing your request. Please try again later.',
      },
      { status: 500 },
    );
  }
}

