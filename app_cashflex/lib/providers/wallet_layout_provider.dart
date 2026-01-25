import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/layout_service.dart';
import 'layout_provider.dart';

/// Provider to fetch wallet page layout configuration
final walletLayoutConfigProvider = FutureProvider<LayoutConfig?>((ref) async {
  final layoutType = ref.watch(layoutTypeProvider);
  return LayoutService.loadLayout(layoutType);
});

