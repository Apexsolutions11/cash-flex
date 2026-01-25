import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/external_app_provider.dart';
import '../../widgets/shimmer_widget.dart' show ExternalAppShimmerCard;
import 'promotion_app_card.dart';

class ExternalApp1Card extends ConsumerWidget {
  const ExternalApp1Card({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(externalApp1Provider);

    return appAsync.when(
      data: (app) => PromotionAppCard(app: app),
      loading: () => const ExternalAppShimmerCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
