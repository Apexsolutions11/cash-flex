import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

typedef ComponentId = String;
typedef LayoutType = String;

class ComponentConfig {
  final String id;
  final bool enabled;
  final int order;
  final String type; // 'component' | 'heading'
  final String? title; // for headings
  final String? badgeText;
  final String? badgeVariant;
  final bool? shakeAnimationEnabled; // for gemee-jackpot shake animation

  ComponentConfig({
    required this.id,
    required this.enabled,
    required this.order,
    this.type = 'component',
    this.title,
    this.badgeText,
    this.badgeVariant,
    this.shakeAnimationEnabled,
  });

  factory ComponentConfig.fromJson(Map<String, dynamic> json) {
    final dynamic rawType = json['type'];
    final String parsedType =
        rawType is String && rawType.trim().isNotEmpty ? rawType.trim() : 'component';

    final dynamic rawTitle = json['title'];
    final String? parsedTitle =
        rawTitle is String && rawTitle.trim().isNotEmpty ? rawTitle.trim() : null;

    final dynamic rawBadgeText = json['badgeText'];
    final String? parsedBadgeText = rawBadgeText is String ? rawBadgeText.trim() : null;

    final dynamic rawBadgeVariant = json['badgeVariant'];
    final String? parsedBadgeVariant = rawBadgeVariant is String ? rawBadgeVariant.trim() : null;

    final dynamic rawShakeAnimation = json['shakeAnimationEnabled'];
    final bool? parsedShakeAnimation = rawShakeAnimation is bool ? rawShakeAnimation : null;

    return ComponentConfig(
      id: json['id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      type: parsedType,
      title: parsedTitle,
      badgeText: parsedBadgeText != null && parsedBadgeText.isNotEmpty ? parsedBadgeText : null,
      badgeVariant: parsedBadgeVariant != null && parsedBadgeVariant.isNotEmpty ? parsedBadgeVariant : null,
      shakeAnimationEnabled: parsedShakeAnimation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enabled': enabled,
      'order': order,
      if (type != 'component') 'type': type,
      if (title != null) 'title': title,
      if (badgeText != null) 'badgeText': badgeText,
      if (badgeVariant != null) 'badgeVariant': badgeVariant,
      if (shakeAnimationEnabled != null) 'shakeAnimationEnabled': shakeAnimationEnabled,
    };
  }
}

class PageLayoutConfig {
  final List<ComponentConfig> homepage;
  final List<ComponentConfig> wallet;
  final List<ComponentConfig> invite;

  PageLayoutConfig({
    required this.homepage,
    required this.wallet,
    required this.invite,
  });

  factory PageLayoutConfig.fromJson(Map<String, dynamic> json) {
    final homepageList = json['homepage'] as List<dynamic>? ?? [];
    final walletList = json['wallet'] as List<dynamic>? ?? [];
    final inviteList = json['invite'] as List<dynamic>? ?? [];
    
    return PageLayoutConfig(
      homepage: homepageList
          .map((comp) => ComponentConfig.fromJson(comp as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      wallet: walletList
          .map((comp) => ComponentConfig.fromJson(comp as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      invite: inviteList
          .map((comp) => ComponentConfig.fromJson(comp as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homepage': homepage.map((c) => c.toJson()).toList(),
      'wallet': wallet.map((c) => c.toJson()).toList(),
      'invite': invite.map((c) => c.toJson()).toList(),
    };
  }
}

class LayoutConfig {
  final String type;
  final PageLayoutConfig pageLayout;

  LayoutConfig({
    required this.type,
    required this.pageLayout,
  });

  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      type: json['type'] as String? ?? 'normal',
      pageLayout: PageLayoutConfig.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...pageLayout.toJson(),
    };
  }
}

class LayoutService {
  LayoutService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the layout type based on user's country or other criteria
  /// Defaults to 'google' layout. Other layouts can be enabled via flags.
  static LayoutType getLayoutType() {
    // Import constants to check layout flags
    // Note: These flags are managed in admin panel and loaded via AppConfigService
    // Implement additional logic to determine layout type based on:
    // - User's country (from user document)
    // - User's ISP
    // - A/B testing
    // - Other conditions
    
    // For now, check flags from constants (loaded from Firestore via AppConfigService)
    // Default to 'google' layout
    return 'google';
  }

  /// Load layout configuration from Firestore
  static Future<LayoutConfig?> loadLayout(LayoutType type) async {
    try {
      final layoutsDoc = await _firestore.collection('admin').doc('layouts').get();

      if (!layoutsDoc.exists) {
        debugPrint('Layouts document does not exist, using default');
        return null;
      }

      final data = layoutsDoc.data();
      if (data == null) {
        return null;
      }

      final layoutData = data[type.toString()];
      if (layoutData == null) {
        debugPrint('Layout $type not found, using default');
        return null;
      }

      return LayoutConfig.fromJson(layoutData as Map<String, dynamic>);
    } catch (e, s) {
      debugPrint('Failed to load layout: $e\n$s');
      return null;
    }
  }

  /// Get enabled components in order
  static List<ComponentConfig> getEnabledComponents(List<ComponentConfig> components) {
    return components.where((c) => c.enabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Check if a component should be shown
  static bool shouldShowComponent(
    String componentId,
    List<ComponentConfig> components,
  ) {
    final component = components.firstWhere(
      (c) => c.id == componentId,
      orElse: () => ComponentConfig(id: componentId, enabled: true, order: 0),
    );
    return component.enabled;
  }

  static ComponentConfig? findComponentConfig(
    String componentId,
    List<ComponentConfig> components,
  ) {
    for (final c in components) {
      if (c.id == componentId) return c;
    }
    return null;
  }

  /// Check if a wallet page component should be shown
  static bool shouldShowWalletComponent(
    String componentId,
    LayoutConfig? layoutConfig,
  ) {
    if (layoutConfig == null) return true; // Default to showing if no config
    return shouldShowComponent(componentId, layoutConfig.pageLayout.wallet);
  }

  /// Check if an invite page component should be shown
  static bool shouldShowInviteComponent(
    String componentId,
    LayoutConfig? layoutConfig,
  ) {
    if (layoutConfig == null) return true; // Default to showing if no config
    return shouldShowComponent(componentId, layoutConfig.pageLayout.invite);
  }

  /// Check if a homepage component should be shown
  static bool shouldShowHomepageComponent(
    String componentId,
    LayoutConfig? layoutConfig,
  ) {
    if (layoutConfig == null) return true; // Default to showing if no config
    return shouldShowComponent(componentId, layoutConfig.pageLayout.homepage);
  }
}

