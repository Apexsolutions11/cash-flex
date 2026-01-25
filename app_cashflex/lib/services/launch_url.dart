import 'package:url_launcher/url_launcher.dart';

import '../utils/helper/toast_manager.dart';

class LaunchUrl {
  static Future<void> inWeb(String url) async {
    if (url.isEmpty) {
      ToastManager.error(msg: 'Failed to open the link.');
      return;
    }

    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ToastManager.error();
    }
  }
}
