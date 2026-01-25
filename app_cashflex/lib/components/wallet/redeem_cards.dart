import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cashflex/models/wallet/wallet_catalog_model.dart';
import 'package:cashflex/theme/app_theme.dart';

import '../../../../../utils/helper/helper.dart';
import 'alert_popup.dart';

class RedeemCards extends StatelessWidget {
  const RedeemCards({
    super.key,
    required this.denominations,
    required this.catalogData,
    required this.balance,
    required this.selIndex,
  });

  final List<Denomination> denominations;
  final WalletCatalogData catalogData;
  final int balance;
  final ValueNotifier<int?> selIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.9,
      ),
      itemCount: denominations.length,
      itemBuilder: (context, index) {
        final isLocked = !denominations[index].enabled;
        final progress = (balance / denominations[index].coins).clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () {
            if (isLocked) {
              showPaymentAlertPopup(
                context,
                'Alert',
                'This voucher is currently locked for you. Please earn more coins to unlock it.',
              );
            } else {
              selIndex.value = index;
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.darkTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppTheme.darkTheme.colorScheme.surface,
                width: selIndex.value == index ? 2 : 0,
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Spacer(),
                      Image.asset(
                        'assets/icons/${catalogData.id.img()}.png',
                        height: 70.h,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${catalogData.symbol} ${denominations[index].amount}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: AppTheme.darkTheme.colorScheme.surface,
                            ),
                          ),
                          const Spacer(),
                          Image.asset('assets/images/coin.png', height: 18.h),
                          const SizedBox(width: 4),
                          Text(
                            denominations[index].coins.addComma(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppTheme.darkTheme.colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: LinearProgressIndicator(
                          value: progress,
                          borderRadius: BorderRadius.circular(200),
                          backgroundColor: AppTheme
                              .darkTheme
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.darkTheme.colorScheme.surface,
                          ),
                          minHeight: 10.h,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Visibility(
                    visible: isLocked,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.darkTheme.colorScheme.surface
                            .withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: AppTheme.darkTheme.colorScheme.surface,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 5,
                  child: Visibility(
                    visible: selIndex.value == index,
                    child: Icon(
                      Icons.check_circle_outlined,
                      color: AppTheme.darkTheme.colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
