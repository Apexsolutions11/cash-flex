import axios from 'axios';
import { projectId } from '../../firebase-admin';
import * as constant from '../../constants';
import { PaymentMethod } from './payment-helper';
import { getSettings } from '../settings-helper';

export const payWithXoxoday = async (
  amount: number,
  email: string,
  orderId: string,
  userEmail: string,
  userId: string,
  deviceId: string,
  ip: string,
  lat: string,
  lon: string,
  paymentMethod: PaymentMethod,
): Promise<Record<string, string>> => {
  const settings = await getSettings();
  let productId;

  if (paymentMethod == PaymentMethod.AMAZON) {
    productId = constant.xdAmazonPid;
  } else if (paymentMethod == PaymentMethod.DANA) {
    productId = constant.xdDanaPid;
  } else if (paymentMethod == PaymentMethod.FLIPKART) {
    productId = constant.xdFlipkartPid;
  } else if (paymentMethod == PaymentMethod.GCASH) {
    productId = constant.xdGCashPid;
  } else if (paymentMethod == PaymentMethod.GOOGLE_PLAY) {
    productId = constant.xdGooglePlayPid;
  } else if (paymentMethod == PaymentMethod.PAYPAL) {
    productId = constant.xdPaypalPid;
  } else if (paymentMethod == PaymentMethod.TOUCH_N_GO) {
    productId = constant.xdTouchNGoPid;
  } else {
    return {
      response: 'failure',
      reason: `Invalid payment method: ${paymentMethod}.`,
    };
  }

  const requestData = {
    remarks: 'Payout from ' + settings.appName,
    amount: amount,
    order_id: orderId,
    email: email,
    productId: String(productId),
    api_key: settings.payoutKey,
    project_id: projectId,
    user_email: userEmail,
    app_uuid: userId,
    user_device_id: deviceId,
    user_ip: ip,
    user_lat: lat,
    user_long: lon,
  };

  try {
    const response = await axios.post(constant.xoxoday.request, requestData, {
      headers: {
        'X-Secure-Key': settings.secureKey,
        'Content-Type': 'application/json',
      },
    });

    console.log(response.data);

    if (response.status === 200) {
      return {
        response: 'success',
        status: response.data.status,
        txId: response.data.tr_id,
        voucherCode: response.data.voucherCode,
        provider: 'xoxoday',
      };
    } else {
      return {
        response: 'failure',
        reason: 'Unknown status ' + response.status,
      };
    }
  } catch (error) {
    return {
      response: 'failure',
      reason: 'Error while processing payout request ' + error,
    };
  }
};

