import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/layout_service.dart';

/// Global variable to store layout type determined on splash screen
/// This is set once on splash screen and used throughout the app session
LayoutType? _cachedLayoutType;

/// Set the layout type (called from splash screen)
void setLayoutType(LayoutType layoutType) {
  _cachedLayoutType = layoutType;
}

/// Provider to get layout type (uses the stored value from splash screen)
/// If not set yet, defaults to 'google' layout
final layoutTypeProvider = Provider<LayoutType>((ref) {
  return _cachedLayoutType ?? 'google'; // Default to google if not determined yet
});

/// Provider to fetch and cache layout configuration
final layoutConfigProvider = FutureProvider<LayoutConfig?>((ref) async {
  final layoutType = ref.watch(layoutTypeProvider);
  return LayoutService.loadLayout(layoutType);
});

/// Provider to fetch wallet page layout configuration
final walletLayoutConfigProvider = FutureProvider<LayoutConfig?>((ref) async {
  final layoutType = ref.watch(layoutTypeProvider);
  return LayoutService.loadLayout(layoutType);
});

