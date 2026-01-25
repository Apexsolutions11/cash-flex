import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'toast_manager.dart';

extension ExtString on String {
  bool get isValidName => RegExp(r'^[A-Za-z ]{3,}$').hasMatch(this);

  bool get isValidUPI => RegExp(r'^[\w.-]+@+[\w.]+$').hasMatch(this);

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidAccountNumber => RegExp(r'^\d{9,18}$').hasMatch(this);

  bool get isValidIFSC => RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(this);

  String caps() {
    final List<String> words = split('_');
    final List<String> capitalizedWords = words.map((word) {
      if (word.isNotEmpty) {
        if (word.contains(RegExp(r'[A-Z]'))) {
          final splitWords = word.replaceAllMapped(
            RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)} ${match.group(2)}',
          );
          return splitWords.split(' ').map((part) {
            return part[0].toUpperCase() + part.substring(1).toLowerCase();
          }).join(' ');
        } else {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }
      } else {
        return '';
      }
    }).toList();
    return capitalizedWords.join(' ');
  }

  String img() {
    return replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .toLowerCase();
  }

  IconData get getIcon {
    switch (this) {
      case 'LEADERBOARD':
        return Icons.leaderboard_rounded;

      case 'REFERRAL':
        return Icons.person_add_rounded;

      case 'FOLLOW_REWARD':
        return Icons.group_rounded;

      default:
        return Icons.card_giftcard;
    }
  }

  String parseSymbol() {
    final regex = RegExp(r'\\u[0-9A-Fa-f]{4}');
    final matches = regex.allMatches(this);

    return matches.map((match) {
      final unicode = match.group(0)?.substring(2);
      return unicode != null
          ? String.fromCharCode(int.parse(unicode, radix: 16))
          : '';
    }).join('');
  }
}

extension ExtInt on int {
  String formatCoins() {
    String output = '';
    if (this > 999 && this < 99999) {
      output = '${(this / 1000).toStringAsFixed(1)}K';
    } else if (this > 99999 && this < 999999) {
      output = '${(this / 1000).toStringAsFixed(0)}K';
    } else if (this > 999999 && this < 999999999) {
      output = '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this > 999999999) {
      output = '${(this / 1000000000).toStringAsFixed(1)}B';
    } else {
      output = toString();
    }

    return output;
  }

  String addComma() {
    final String numberString = toString();
    String output = '';

    int count = 0;
    for (int i = numberString.length - 1; i >= 0; i--) {
      output = numberString[i] + output;
      count++;

      if (count == 3 && i > 0) {
        output = ',$output';
        count = 0;
      }
    }

    return output;
  }

  String formatMs() {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(this);

    final String year = dateTime.year.toString();
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');

    int hour = dateTime.hour;
    final int minute = dateTime.minute;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour != 0 ? hour : 12;
    final String hourStr = hour.toString().padLeft(2, '0');
    final String minuteStr = minute.toString().padLeft(2, '0');

    final Duration timezoneOffset = dateTime.timeZoneOffset;
    final String hoursOffset =
        timezoneOffset.inHours.abs().toString().padLeft(2, '0');
    final String minutesOffset =
        (timezoneOffset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final String sign = timezoneOffset.isNegative ? '-' : '+';

    return '$year-$month-$day $hourStr:$minuteStr $amPm (UTC$sign$hoursOffset:$minutesOffset)';
  }
}

extension ExtTimeStamp on Timestamp {
  String formatTimestamp() {
    final DateTime timestampAsDateTime = toDate();
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(timestampAsDateTime);
    String time = '';

    if (diff.inSeconds <= 0 ||
        diff.inSeconds > 0 && diff.inMinutes == 0 ||
        diff.inMinutes > 0 && diff.inHours == 0 ||
        diff.inHours > 0 && diff.inDays == 0) {
      if (diff.isNegative || (diff.inSeconds >= 0 && diff.inSeconds < 60)) {
        time = 'just now';
      }
      if (diff.inMinutes >= 1 && diff.inMinutes < 60) {
        time = '${diff.inMinutes} minute(s) ago';
      }
      if (diff.inHours >= 1 && diff.inHours < 24) {
        time = '${diff.inHours} hour(s) ago';
      }
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      time = '${diff.inDays} day(s) ago';
    } else {
      time = '${(diff.inDays / 7).floor()} week(s) ago';
    }
    return time;
  }
}

extension ExtDouble on double {
  String formatBalance() {
    final double curValDouble = toDouble();
    final int curValInt = int.parse(curValDouble.toStringAsFixed(0));

    final String finalCurVal = curValInt == curValDouble
        ? curValInt.toString()
        : curValDouble.toStringAsFixed(2);

    return finalCurVal;
  }
}

String? nameValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your name';
  }
  if (!value.isValidName) {
    return 'Please enter a valid name (at least 3 characters, alphabets only)';
  }
  return null;
}

String? emailValidator(String? email) {
  if (email == null || email.isEmpty) {
    return 'Please enter your email';
  }
  if (!email.isValidEmail) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? upiValidator(String? upi) {
  if (upi == null || upi.isEmpty) {
    return 'Please enter your UPI address';
  }
  if (!upi.isValidUPI) {
    return 'Please enter a valid UPI address';
  }
  return null;
}

String? bankAccValidator(String? accNo) {
  if (accNo == null || accNo.isEmpty) {
    return 'Please enter your bank account number';
  }
  if (!accNo.isValidAccountNumber) {
    return 'Please enter a valid bank account number';
  }
  return null;
}

String? ifscValidator(String? ifsc) {
  if (ifsc == null || ifsc.isEmpty) {
    return 'Please enter your bank IFSC code';
  }
  if (!ifsc.isValidIFSC) {
    return 'Please enter a valid IFSC code';
  }
  return null;
}

//! Copy data to clipboard
Future<void> copyData(String data) async {
  await Clipboard.setData(ClipboardData(text: data));
  ToastManager.success(
    'Copied to clipboard',
  );
}

String formatTimeDifference(int leaderboardTimeLeft) {
  final int currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
  final int timeDifferenceMillis = leaderboardTimeLeft - currentTimeMillis;

  if (timeDifferenceMillis <= 0) {
    return 'Daily task limit reached. Please try again later.';
  }

  final int hours = (timeDifferenceMillis ~/ (1000 * 60 * 60)) % 24;
  final int minutes = (timeDifferenceMillis ~/ (1000 * 60)) % 60;

  if (hours > 0) {
    return 'Task completed. Please try again after $hours hours $minutes minutes.';
  } else {
    return 'Task completed. Please try again after $minutes minutes.';
  }
}
