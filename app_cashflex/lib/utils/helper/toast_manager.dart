import 'package:flutter/material.dart';
import 'package:cashflex/theme/app_theme.dart';
import 'package:toastification/toastification.dart';


class ToastManager {
  static void success(String message) {
    toastification.show(
      description: Text(message),
      borderSide: BorderSide(
        color: AppTheme.darkTheme.colorScheme.primary,
      ),
      borderRadius: BorderRadius.circular(20),
      type: ToastificationType.success,
      alignment: Alignment.bottomCenter,
      closeOnClick: true,
      dragToClose: true,
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.always,
      

      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void error({
    String msg = 'Something went wrong. Please try again later.',
  }) {
    toastification.show(
      description: Text(msg),
      borderSide: BorderSide(
        color: AppTheme.darkTheme.colorScheme.primary,
      ),
      borderRadius: BorderRadius.circular(20),
      type: ToastificationType.error,
      alignment: Alignment.bottomCenter,
      closeOnClick: true,
      closeButtonShowType: CloseButtonShowType.always,
      dragToClose: true,
      showProgressBar: true,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void warning(String message) {
    toastification.show(
      description: Text(message),
      borderSide: BorderSide(
        color: AppTheme.darkTheme.colorScheme.primary,
      ),
      borderRadius: BorderRadius.circular(20),
      type: ToastificationType.warning,
      alignment: Alignment.bottomCenter,
      closeOnClick: true,
      closeButtonShowType: CloseButtonShowType.always,
      dragToClose: true,
      showProgressBar: true,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void info(String message) {
    toastification.show(
      description: Text(message),
      borderSide: BorderSide(
        color: AppTheme.darkTheme.colorScheme.primary,
      ),
      borderRadius: BorderRadius.circular(20),
      type: ToastificationType.info,
      alignment: Alignment.bottomCenter,
      closeOnClick: true,
      dragToClose: true,
      showProgressBar: true,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
