import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../models/wallet/payment_method.dart';
import '../providers/wallet/payment_method_provider.dart';
import '../providers/layout_provider.dart';
import '../utils/constant/constant.dart';
import '../theme/app_theme.dart';
import 'redeem_denominations_page.dart';
import '../components/wallet/warning_card.dart';

class RedeemPage extends ConsumerStatefulWidget {
  final String country;
  final String userId;
  final int balance;

  const RedeemPage({
    super.key,
    required this.country,
    required this.userId,
    required this.balance,
  });

  @override
  ConsumerState<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends ConsumerState<RedeemPage> {
  List<PaymentMethod>? paymentMethods;
  bool loadingMethods = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await ref.read(
        paymentMethodProvider(widget.country).future,
      );
      setState(() {
        paymentMethods = methods;
        loadingMethods = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment methods: $e')),
        );
      }
      setState(() {
        loadingMethods = false;
      });
    }
  }

  Widget _methodImageOrIcon(PaymentMethod method) {
    final url = method.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const Icon(TablerIcons.wallet, size: 26, color: Colors.blue);
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(TablerIcons.wallet, size: 26, color: Colors.blue);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  Widget _buildTopBalanceCard(String layoutType) {
    final isNormal = layoutType == 'normal';
    final factor = isNormal ? indiaCoinCurFactor : foreignCoinCurFactor;
    final currencySymbol = isNormal ? '₹' : '\$';
    final convertedAmount = factor > 0 ? (widget.balance / factor) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient1,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/coin.png', width: 34, height: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.balance}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (factor > 0 && convertedAmount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '≈ $currencySymbol${convertedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingMethods) {
      return Scaffold(
        appBar: AppBar(title: const Text('Redeem')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (paymentMethods == null || paymentMethods!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Redeem')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                TablerIcons.alert_circle,
                size: 64,
                color: Colors.white60,
              ),
              const SizedBox(height: 16),
              const Text(
                'No payment methods available',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Show payment method selection (denominations load on a separate page)
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Payment Method')),
      body: Consumer(
        builder: (context, ref, _) {
          // Get layout type from provider (determined on splash screen, no async needed)
          final layoutType = ref.watch(layoutTypeProvider);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBalanceCard(layoutType),
                const SizedBox(height: 16),
                WarningCard(notice: redeemNotice),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                    itemCount: paymentMethods!.length,
                    itemBuilder: (context, index) {
                      final method = paymentMethods![index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RedeemDenominationsPage(
                                userId: widget.userId,
                                country: widget.country,
                                paymentMethod: method,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                                child: _methodImageOrIcon(method),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                method.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              const Icon(
                                TablerIcons.chevron_right,
                                color: Colors.black38,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
