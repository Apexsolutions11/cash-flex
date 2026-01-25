import { NextRequest, NextResponse } from 'next/server';
import { db, admin } from '@/lib/firebase-admin';
import axios from 'axios';
import * as constant from '@/lib/constants';
import * as other from '@/lib/helpers/other-service';
import { getSettings } from '@/lib/helpers/settings-helper';
import { verifyCronAuth } from '@/lib/middleware/cron-auth';

export async function POST(request: NextRequest) {
  if (!verifyCronAuth(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  try {
    const paymentDbRef = db.collection('transactionRecord');
    const paymentDocs = await paymentDbRef
      .where('status', '==', 'processing')
      .where('provider', '==', 'cashfree')
      .where('txnId', '!=', '')
      .limit(50)
      .get();

    if (paymentDocs.empty) {
      console.log('No pending cashfree payments');
      return NextResponse.json({ success: true });
    }

    const batch = db.batch();

    for (const doc of paymentDocs.docs) {
      try {
        const docData = doc.data();
        const orderId = doc.id;
        const coins = docData.coins;
        const txnId = docData.txnId;

        const settings = await getSettings();
        const requestData = {
          reference_id: txnId,
          transfer_id: orderId,
          api_key: settings.payoutKey,
        };

        const response = await axios.post(constant.cashfree.status, requestData, {
          headers: {
            'X-Secure-Key': settings.secureKey,
            'Content-Type': 'application/json',
          },
        });

        if (response.status === 200) {
          if (response.data.status == 'success') {
            batch.update(doc.ref, {
              status: 'paid',
              exTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

            const userDoc = await db
              .collection('users')
              .doc(docData.userId)
              .collection('transactionHistory')
              .doc(orderId)
              .get();

            batch.update(userDoc.ref, {
              status: 'paid',
            });

            await other.sendFcmNotificationViaUid(docData.userId, {
              title: 'Payment Success',
              body: 'Your payment has been successfully processed',
            });
          } else if (response.data.status == 'failed') {
            batch.update(doc.ref, {
              status: 'failed',
              exTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

            const userDoc = await db.collection('users').doc(docData.userId).get();
            const userDocTxnColl = await userDoc.ref.collection('transactionHistory').doc(orderId).get();

            batch.update(userDoc.ref, {
              balance: admin.firestore.FieldValue.increment(coins),
              totalPayoutCount: admin.firestore.FieldValue.increment(-1),
            });

            batch.update(userDocTxnColl.ref, {
              status: 'failed',
            });

            await other.sendFcmNotificationViaUid(docData.userId, {
              title: 'Payment Failed',
              body: 'Your payment request has been failed, the coins has been refunded to your wallet',
            });
          }
        } else {
          console.error(`Error processing transaction ${doc.id}:`);
        }
      } catch (error) {
        console.error(`Error processing transaction ${doc.id}:`, error);
      }
    }
    await batch.commit();

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error fetching payment documents:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

