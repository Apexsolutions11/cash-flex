import 'package:dio/dio.dart';

import '../utils/constant/constant.dart';

class UserValidation {
  static Future<bool> validate() async {
    try {
      final response = await Dio().get(AppConstant.ipApiUrl);
      final ipApiResponse = response.data;

      if (ipApiResponse['status'] != 'success') {
        return false;
      }

      final String isp = ipApiResponse['isp'];

      if (_checkKeyword(isp)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _checkKeyword(String value) =>
      value.toLowerCase().contains('google');
}
