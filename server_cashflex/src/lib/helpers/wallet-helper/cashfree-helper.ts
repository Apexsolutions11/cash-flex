import axios from 'axios';
import { projectId } from '../../firebase-admin';
import * as constant from '../../constants';
import { getSettings } from '../settings-helper';

export const payWithCashfree = async (
  amount: number,
  orderId: string,
  upi: string,
  email: string,
  name: string,
  userId: string,
  deviceId: string,
  userEmail: string,
  ip: string,
  lat: string,
  lon: string,
): Promise<Record<string, string>> => {
  const settings = await getSettings();
  const requestData = {
    upi: upi,
    name: name,
    amount: amount,
    email: email,
    order_id: orderId,
    remarks: 'Payout from ' + settings.appName,
    project_id: projectId,
    api_key: settings.payoutKey,
    app_uuid: userId,
    user_device_id: deviceId,
    user_email: userEmail,
    user_ip: ip,
    user_lat: lat,
    user_long: lon,
  };

  console.log(requestData);

  try {
    const response = await axios.post(constant.cashfree.request, requestData, {
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
        provider: 'cashfree',
      };
    } else {
      return {
        response: 'failure',
        reason: 'Failed to place order ',
      };
    }
  } catch (error) {
    return {
      response: 'failure',
      reason: 'Error while processing payout request: ' + (error as Error).message,
    };
  }
};

