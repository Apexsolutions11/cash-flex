import { admin, db } from '../../firebase-admin';
import * as other from '../other-service';

export const paymentRecord = async (
  userId: string,
  coins: number,
  amount: number,
  symbol: string,
  status: string,
  ipAddress: string,
  methodDetails: any,
  orderId: string,
  txnId: string,
  provider: string,
  fcmToken: string,
  method: string,
  voucherCode: string,
  country: string,
): Promise<Record<string, string>> => {
  try {
    const fieldValue = admin.firestore.FieldValue;

    const timestamp = fieldValue.serverTimestamp();
    const timestampMs = Date.now();

    const userDbRef = db.collection('users').doc(userId);

    const transactionRecordColl = userDbRef.collection('transactionHistory');

    const globalTransactionRecordColl = db.collection('transactionRecord');

    const batch = db.batch();

    batch.update(userDbRef, {
      balance: fieldValue.increment(-1 * coins),
      dailyPayoutCount: fieldValue.increment(1),
      totalPayoutCount: fieldValue.increment(1),
    });

    batch.set(transactionRecordColl.doc(orderId), {
      coins: coins,
      amount: amount,
      symbol: symbol,
      status: status,
      orderId: orderId,
      txnId: txnId,
      timestamp: timestamp,
      timestampMs: timestampMs,
      [method]: methodDetails,
      voucherCode: voucherCode,
    });

    batch.set(globalTransactionRecordColl.doc(orderId), {
      userId: userId,
      coins: coins,
      amount: amount,
      symbol: symbol,
      status: status,
      ipAddress: ipAddress,
      orderId: orderId,
      txnId: txnId,
      provider: provider,
      timestamp: timestamp,
      timestampMs: timestampMs,
      exTimestamp: status == 'paid' ? timestamp : null,
      [method]: methodDetails,
      voucherCode: voucherCode,
      country: country,
    });

    await batch.commit();

    if (fcmToken) {
      await other.sendFcmNotification({
        notification: {
          title: 'Payment Request 💰',
          body:
            status == 'paid'
              ? 'Your payment request has been processed successfully.'
              : 'Your payment request is in progress and will be processed within 5 minutes.',
        },
        token: fcmToken,
      });
    }

    return {
      response: 'success',
    };
  } catch (error) {
    return {
      response: 'failure',
      reason: error instanceof Error ? error.message : String(error),
    };
  }
};

