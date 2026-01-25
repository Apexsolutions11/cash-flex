import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../theme/app_theme.dart';

import '../models/wallet/payment_method.dart';
import '../theme/app_theme.dart';
import '../models/wallet/payment_details_model.dart';
import '../theme/app_theme.dart';
import '../models/wallet/wallet_catalog_model.dart';
import '../theme/app_theme.dart';
import '../providers/wallet/balance_payment_details_provider.dart';
import '../theme/app_theme.dart';
import '../providers/wallet/wallet_catalog_provider.dart';
import '../theme/app_theme.dart';
import '../providers/layout_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../services/wallet/handle_payment_request.dart';
import '../theme/app_theme.dart';
import '../utils/constant/constant.dart';
import '../theme/app_theme.dart';
import '../utils/helper/helper.dart';
import '../theme/app_theme.dart';
import '../utils/helper/jackpot_check_helper.dart';
import '../theme/app_theme.dart';
import 'enter_details_page.dart';
import '../theme/app_theme.dart';
import '../components/wallet/warning_card.dart';
import '../theme/app_theme.dart';

class RedeemDenominationsPage extends ConsumerStatefulWidget {
  final String userId;
  final String country;
  final PaymentMethod paymentMethod;

  const RedeemDenominationsPage({
    super.key,
    required this.userId,
    required this.country,
    required this.paymentMethod,
  });

  @override
  ConsumerState<RedeemDenominationsPage> createState() =>
      _RedeemDenominationsPageState();
}

class _RedeemDenominationsPageState
    extends ConsumerState<RedeemDenominationsPage> {
  int? selectedCatalogIndex;
  bool isLoading = false;
  int leaderboardTimeLeft = 0;

  Widget _imageOrFallback({
    required String? imageUrl,
    required IconData fallbackIcon,
    double iconSize = 26,
  }) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return Icon(fallbackIcon, size: iconSize, color: Colors.black26);
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: iconSize, color: Colors.black26);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  String? _bestVoucherImageUrl(Denomination d, WalletCatalog catalog) {
    return d.imageUrl ??
        widget.paymentMethod.imageUrl ??
        catalog.catalog.imageUrl;
  }

  String _resolveUid() {
    final fromArgs = widget.userId.trim();
    if (fromArgs.isNotEmpty) return fromArgs;
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadLeaderboardTime();
  }

  Future<void> _loadLeaderboardTime() async {
    try {
      final serverTime = await ApiService.getServerTime();
      // Backends may return either `status` or `response`.
      final String status =
          (serverTime['status'] ?? serverTime['response'] ?? '').toString();
      final dynamic raw = serverTime['leaderboardTimeLeft'];
      if (status == 'success' && raw != null) {
        setState(() {
          leaderboardTimeLeft = (raw as num).toInt();
        });
      }
    } catch (e) {
      // Non-fatal; redemption will still work (backend handles timing)
      debugPrint('Error loading leaderboard time: $e');
    }
  }

  Widget _buildContent({
    required WalletCatalog catalog,
    required int balance,
    required bool methodAvailable,
    required PaymentDetails paymentDetails,
    required String layoutType,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Info Card
          Builder(
            builder: (context) {
              final isNormal = layoutType == 'normal';
              final factor = isNormal ? indiaCoinCurFactor : foreignCoinCurFactor;
              final currencySymbol = isNormal ? '₹' : '\$';
              final convertedAmount = factor > 0 ? (balance / factor) : 0.0;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/coin.png',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$balance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (factor > 0 && convertedAmount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '≈ $currencySymbol${convertedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          WarningCard(notice: redeemNotice),

          const SizedBox(height: 24),

          // Payment details card / CTA
          Card(
            color: const Color(0xFF1A1A1A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    methodAvailable
                        ? TablerIcons.discount_check
                        : TablerIcons.alert_triangle,
                    color: methodAvailable
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          methodAvailable
                              ? 'Payment details saved'
                              : 'Payment details required',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          methodAvailable
                              ? _detailsSummary(
                                  widget.paymentMethod.id,
                                  paymentDetails,
                                )
                              : 'Please add your ${widget.paymentMethod.title} details before redeeming.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      final uid = _resolveUid();
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EnterDetailsPage(
                            uid: uid,
                            paymentMethod: widget.paymentMethod,
                            paymentDetails: paymentDetails,
                          ),
                        ),
                      );
                    },
                    child: Text(methodAvailable ? 'Edit' : 'Add'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Select Voucher',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          if (catalog.denominations.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.78,
              ),
              itemCount: catalog.denominations.length,
              itemBuilder: (context, index) {
                final denomination = catalog.denominations[index];
                final isLocked = !denomination.enabled;
                final progress = (balance / denomination.coins).clamp(0.0, 1.0);

                final bool isSelected = selectedCatalogIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This voucher is currently locked. Please earn more coins to unlock it.',
                          ),
                        ),
                      );
                    } else {
                      setState(() {
                        selectedCatalogIndex = index;
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.black12,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.05),
                                  ),
                                ),
                                child: _imageOrFallback(
                                  imageUrl: _bestVoucherImageUrl(
                                    denomination,
                                    catalog,
                                  ),
                                  fallbackIcon: TablerIcons.gift,
                                  iconSize: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${catalog.catalog.symbol} ${denomination.amount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/coin.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      denomination.coins.addComma(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.blueAccent,
                                      ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            ),
                          ),
                        ),
                      if (isLocked)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            TablerIcons.lock,
                            color: Colors.black54,
                            size: 18,
                          ),
                        ),
                      if (isSelected && !isLocked)
                        const Positioned(
                          top: 10,
                          left: 10,
                          child: Icon(
                            TablerIcons.discount_check,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No vouchers available',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
              ),
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppTheme.buildGradientButton(
              onPressed: (!methodAvailable || isLoading)
                  ? null
                  : () async {
                      if (selectedCatalogIndex == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a voucher first'),
                          ),
                        );
                        return;
                      }

                      // Check layout type - don't show geemee dialog if Google layout is applied
                      final layoutType = ref.read(layoutTypeProvider);
                      if (layoutType != 'google') {
                        // Check if user needs to play jackpot (admin-controlled)
                        final canProceed =
                            await JackpotCheckHelper.checkAndShowDialogIfNeeded(
                              context,
                              dialogTitle: 'Play Required',
                              dialogMessage:
                                  'To redeem coins, you must play the Lucky Bonus at least once today. Click "Play Now" to open the Lucky Bonus.',
                            );
                        if (!canProceed) {
                          return;
                        }
                      }

                      setState(() {
                        isLoading = true;
                      });

                      await handlePaymentRequest(
                        context,
                        selectedCatalogIndex,
                        balance,
                        catalog,
                        leaderboardTimeLeft,
                      );

                      if (!mounted) return;

                      setState(() {
                        isLoading = false;
                        selectedCatalogIndex = null;
                      });
                    },
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      methodAvailable ? 'Redeem' : 'Add details to redeem',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _detailsSummary(String methodName, PaymentDetails data) {
    switch (methodName) {
      case 'UPI':
        return 'UPI: ${data.upiId ?? '-'} • Name: ${data.name ?? '-'}';
      case 'NEFT':
        return 'Name: ${data.name ?? '-'} • Acc: ${data.accNo ?? '-'} • IFSC: ${data.ifsc ?? '-'}';
      case 'GOOGLE_PLAY':
      case 'GCASH':
      case 'DANA':
      case 'PAYPAL':
      case 'TOUCH_N_GO':
      case 'FLIPKART':
      case 'AMAZON':
        return 'Email: ${data.email ?? '-'}';
      default:
        return 'Details: -';
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletCatalogAsync = ref.watch(
      walletCatalogProvider(widget.paymentMethod.id),
    );

    final uid = _resolveUid();
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.paymentMethod.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  TablerIcons.alert_circle,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Session expired',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in again to view your balance and redeem rewards.',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.paymentMethod.title),
            const SizedBox(height: 2),
            walletCatalogAsync.when(
              data: (catalog) {
                final curFactor = catalog.catalog.curFactor.toInt();
                final symbol = catalog.catalog.symbol;
                return Text(
                  '$curFactor coins = 1 $symbol',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.black54,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: walletCatalogAsync.when(
        data: (catalog) {
          final params = (uid: uid, method: widget.paymentMethod.id);
          final detailsAsync = ref.watch(balancePaymentDetailsProvider(params));

          return detailsAsync.when(
            data: (details) {
              bool methodAvailable = false;
              try {
                final methodEnum = PaymentMethodEnum.values.firstWhere(
                  (e) => e.name == widget.paymentMethod.id,
                );
                methodAvailable = details.paymentDetails.hasRequiredFields(
                  methodEnum,
                );
              } catch (_) {
                methodAvailable = false;
              }

              // Get layout type from provider (determined on splash screen, no async needed)
              final layoutType = ref.watch(layoutTypeProvider);
              return _buildContent(
                catalog: catalog,
                balance: details.balance,
                methodAvailable: methodAvailable,
                paymentDetails: details.paymentDetails,
                layoutType: layoutType,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      TablerIcons.alert_circle,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load your details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(balancePaymentDetailsProvider(params));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  TablerIcons.alert_circle,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load vouchers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    ref.invalidate(
                      walletCatalogProvider(widget.paymentMethod.id),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
