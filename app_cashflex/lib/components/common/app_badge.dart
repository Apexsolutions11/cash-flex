import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  final String? text;
  final String? variant;
  final bool small;

  const AppBadge({
    super.key,
    required this.text,
    required this.variant,
    this.small = true,
  });

  static String _defaultTextForVariant(String? variant) {
    switch ((variant ?? '').toLowerCase()) {
      case 'popular':
        return 'POPULAR';
      case 'new':
        return 'NEW';
      case 'hot':
        return 'HOT';
      case 'default':
        return 'BADGE';
      case 'none':
      default:
        return '';
    }
  }

  static Color _bgForVariant(String? variant) {
    switch ((variant ?? '').toLowerCase()) {
      case 'popular':
        return const Color(0xFFF59E0B); // amber
      case 'new':
        return const Color(0xFF10B981); // green
      case 'hot':
        return const Color(0xFFEF4444); // red
      case 'default':
        return const Color(0xFF3B82F6); // blue
      default:
        return const Color(0xFF3B82F6);
    }
  }

  static Color _fgForVariant(String? variant) {
    // For the outlined style, text should use the variant color.
    return _bgForVariant(variant);
  }

  @override
  Widget build(BuildContext context) {
    final v = (variant ?? '').trim().toLowerCase();
    if (v == 'none') return const SizedBox.shrink();

    final t = (text ?? '').trim();
    final resolved = t.isNotEmpty ? t : _defaultTextForVariant(variant);
    if (resolved.isEmpty) return const SizedBox.shrink();

    final bg = _bgForVariant(variant);
    final fg = _fgForVariant(variant);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withOpacity(0.85), width: 1),
      ),
      child: Text(
        resolved,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}


