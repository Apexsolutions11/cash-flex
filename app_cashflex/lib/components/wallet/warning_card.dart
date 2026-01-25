import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class WarningCard extends StatelessWidget {
  final String notice;

  const WarningCard({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    if (notice.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(color: AppTheme.warningOrange.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            TablerIcons.alert_triangle,
            color: AppTheme.warningOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notice,
              style: TextStyle(
                color: AppTheme.warningOrange.withOpacity(0.2),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
