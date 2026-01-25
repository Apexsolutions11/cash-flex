// ignore_for_file: constant_identifier_names

enum PaymentMethodEnum {
  UPI,
  GOOGLE_PLAY,
  NEFT,
  PAYPAL,
  GCASH,
  DANA,
  TOUCH_N_GO,
  FLIPKART,
  AMAZON,
}

class PaymentDetails {
  final String? email;
  final String? upiId;
  final String? name;
  final String? accNo;
  final String? ifsc;

  PaymentDetails({
    this.email,
    this.upiId,
    this.name,
    this.accNo,
    this.ifsc,
  });

  Map<String, dynamic> toSnapshot(PaymentMethodEnum method) {
    switch (method) {
      //! UPI
      case PaymentMethodEnum.UPI:
        return {
          'upiId': upiId,
          'name': name,
        };

      //! gCash, DANA, Google Play, Paypal
      case PaymentMethodEnum.GCASH:
      case PaymentMethodEnum.DANA:
      case PaymentMethodEnum.GOOGLE_PLAY:
      case PaymentMethodEnum.PAYPAL:
      case PaymentMethodEnum.TOUCH_N_GO:
      case PaymentMethodEnum.FLIPKART:
      case PaymentMethodEnum.AMAZON:
        return {
          'email': email,
        };

      //! NEFT
      case PaymentMethodEnum.NEFT:
        return {
          'name': name,
          'accNo': accNo,
          'ifsc': ifsc,
        };
    }
  }

  factory PaymentDetails.fromSnapshot(
    Map<String, dynamic> json,
    PaymentMethodEnum method,
  ) {
    switch (method) {
      //! UPI
      case PaymentMethodEnum.UPI:
        return PaymentDetails(
          upiId: json['upiId'],
          name: json['name'],
        );

      //! Google Play, Paypal, Dana, gCash
      case PaymentMethodEnum.GOOGLE_PLAY:
      case PaymentMethodEnum.PAYPAL:
      case PaymentMethodEnum.DANA:
      case PaymentMethodEnum.GCASH:
      case PaymentMethodEnum.TOUCH_N_GO:
      case PaymentMethodEnum.FLIPKART:
      case PaymentMethodEnum.AMAZON:
        return PaymentDetails(
          email: json['email'],
        );

      //! NEFT
      case PaymentMethodEnum.NEFT:
        return PaymentDetails(
          name: json['name'],
          accNo: json['accNo'],
          ifsc: json['ifsc'],
        );
    }
  }

  bool hasRequiredFields(PaymentMethodEnum method) {
    switch (method) {
      //! UPI
      case PaymentMethodEnum.UPI:
        return upiId != null && name != null;

      //! Google Play, gCash, Dana, Paypal
      case PaymentMethodEnum.GOOGLE_PLAY:
      case PaymentMethodEnum.GCASH:
      case PaymentMethodEnum.DANA:
      case PaymentMethodEnum.PAYPAL:
      case PaymentMethodEnum.TOUCH_N_GO:
      case PaymentMethodEnum.FLIPKART:
      case PaymentMethodEnum.AMAZON:
        return email != null;

      //! Bank Transfer
      case PaymentMethodEnum.NEFT:
        return name != null && accNo != null && ifsc != null;
    }
  }
}