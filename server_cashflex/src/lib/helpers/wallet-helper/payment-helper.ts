import { getLatLonForIP } from '../ip-service';
import { formatProvider } from '../other-service';
import * as cashfree from './cashfree-helper';
import * as records from '../record-helper/payment-record';
import * as xoxoday from './xoxoday-helper';

export function splitMethodAndAmount(input: string) {
  const regex = /^([A-Za-z_]+)_(\d+)$/;
  const match = input.match(regex);
  return match
    ? {
        method: match[1],
        amount: parseInt(match[2], 10),
      }
    : {
        method: '',
        amount: 0,
      };
}

export enum PaymentMethod {
  UPI = 'UPI',
  GOOGLE_PLAY = 'GOOGLE_PLAY',
  NEFT = 'NEFT',
  PAYPAL = 'PAYPAL',
  GCASH = 'GCASH',
  DANA = 'DANA',
  TOUCH_N_GO = 'TOUCH_N_GO',
  FLIPKART = 'FLIPKART',
  AMAZON = 'AMAZON',
}

export async function processPaymentRequest(
  methodName: string,
  methodDetails: any,
  amount: number,
  orderId: string,
  userId: string,
  ipAddress: string,
  fcmToken: string,
  coins: number,
  symbol: string,
  email: string,
  deviceId: string,
  country: string,
): Promise<Record<string, string>> {
  const location = await getLatLonForIP(ipAddress);

  let status = '';
  let txnId = '';
  let provider = '';
  let voucherCode = '';

  switch (methodName) {
    case PaymentMethod.UPI:
      if (methodDetails.upiId && methodDetails.name) {
        const res = await cashfree.payWithCashfree(
          amount,
          orderId,
          methodDetails.upiId,
          email,
          methodDetails.name,
          userId,
          deviceId,
          email,
          ipAddress,
          location.lat,
          location.lon,
        );

        if (res.response === 'failure') {
          return {
            response: 'failure',
            reason: `${formatProvider(methodName)} payment failed, please try again later`,
          };
        }

        if (res.status === 'processing') {
          status = 'processing';
        } else if (res.status === 'success') {
          status = 'paid';
        } else {
          return {
            response: 'failure',
            reason: `${formatProvider(methodName)} payment failed, please try again later`,
          };
        }

        txnId = res.txId;
        provider = res.provider;
      } else {
        return {
          response: 'failure',
          reason: `Required ${formatProvider(methodName)} payment details are missing`,
        };
      }
      break;

    case PaymentMethod.GOOGLE_PLAY:
    case PaymentMethod.PAYPAL:
    case PaymentMethod.DANA:
    case PaymentMethod.GCASH:
    case PaymentMethod.AMAZON:
    case PaymentMethod.FLIPKART:
    case PaymentMethod.TOUCH_N_GO:
      if (methodDetails.email) {
        const res = await xoxoday.payWithXoxoday(
          amount,
          methodDetails.email,
          orderId,
          email,
          userId,
          deviceId,
          ipAddress,
          location.lat,
          location.lon,
          methodName,
        );

        if (res.response === 'failure') {
          return {
            response: 'failure',
            reason: `${formatProvider(methodName)} payment failed, please try again later`,
          };
        }

        if (res.status === 'processing') {
          status = 'processing';
        } else if (res.status === 'success') {
          status = 'paid';
        } else {
          return {
            response: 'failure',
            reason: `${formatProvider(methodName)} payment failed, please try again later`,
          };
        }

        txnId = res.txId;
        provider = res.provider;
        voucherCode = res.voucherCode;
      } else {
        return {
          response: 'failure',
          reason: `Required ${formatProvider(methodName)} payment details are missing`,
        };
      }
      break;

    case PaymentMethod.NEFT:
    default:
      return {
        response: 'failure',
        reason: 'Coming soon',
      };
  }

  const recordRes = await records.paymentRecord(
    userId,
    coins,
    amount,
    symbol,
    status,
    ipAddress,
    methodDetails,
    orderId,
    txnId,
    provider,
    fcmToken,
    methodName,
    voucherCode,
    country,
  );

  if (recordRes.response === 'failure') return recordRes;

  return {
    response: 'success',
  };
}

