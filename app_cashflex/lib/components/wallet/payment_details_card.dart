import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cashflex/models/wallet/balance_payment_detail_model.dart';
import 'package:cashflex/models/wallet/payment_method.dart';
import 'package:cashflex/theme/app_theme.dart';

import '../../../../../utils/helper/helper.dart';
import 'payment_details_widget.dart';

class PaymentDetailsCard extends StatelessWidget {
  final BalancePaymentDetailsModel data;
  final bool methodAvailable;
  final VoidCallback onEdit;
  final PaymentMethod method;
  final String symbol;
  final double curFactor;

  const PaymentDetailsCard({
    super.key,
    required this.data,
    required this.methodAvailable,
    required this.onEdit,
    required this.method,
    required this.curFactor,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        color: AppTheme.darkTheme.primaryColor,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  method.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.darkTheme.colorScheme.surface,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: AppTheme.darkTheme.colorScheme.surface
                      .withValues(alpha: 0.3),
                  child: IconButton(
                    icon: Icon(
                      methodAvailable ? Icons.edit_rounded : Icons.add_rounded,
                      color: AppTheme.darkTheme.colorScheme.surface,
                    ),
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/coin.png', height: 20.h),
                    const SizedBox(width: 5),
                    Text(
                      data.balance.addComma(),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkTheme.colorScheme.surface,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '≈ $symbol ${(data.balance / curFactor).formatBalance()}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkTheme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                if (methodAvailable)
                  buildPaymentDetailsWidget(
                    method.id,
                    data.paymentDetails,
                    AppTheme.darkTheme.colorScheme.surface,
                    13,
                  )
                else
                  Text(
                    '${method.title} details are missing.',
                    style: TextStyle(
                      color: AppTheme.darkTheme.colorScheme.surface,
                      fontSize: 14.sp,
                    ),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/icons/${method.id.img()}.png',
                height: 50.h,
                width: 0.3.sw,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
