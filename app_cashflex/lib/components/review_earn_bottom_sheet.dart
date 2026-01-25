import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/background_task_gate.dart';
import '../services/api_service.dart';
import '../utils/helper/toast_manager.dart';
import '../utils/constant/constant.dart';

class ReviewEarnBottomSheet extends StatelessWidget {
  final String url;
  final String appName;
  final int coins;
  final int minBackgroundTime;
  final String taskId;

  const ReviewEarnBottomSheet({
    super.key,
    required this.url,
    required this.appName,
    required this.coins,
    required this.minBackgroundTime,
    required this.taskId,
  });

  String _applyTemplate(String input) {
    var out = input;
    out = out.replaceAll('{name}', appName);
    out = out.replaceAll('{coins}', coins.toString());
    out = out.replaceAll('{seconds}', minBackgroundTime.toString());
    return out;
  }

  List<String> _buildInstructionLines() {
    final template = reviewTaskInstructions.trim();
    final lines = template.isEmpty
        ? <String>[
            'Click the button below to open Play Store',
            'Find and open the app: {name}',
            'Write and submit a review (at least {seconds} seconds)',
            'Return to this app to claim your reward',
          ]
        : template.split('\n');

    return lines
        .map((l) => _applyTemplate(l).trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      BackgroundTaskGate.instance.start(
        minimumBackgroundTime: minBackgroundTime,
        context: context,
        onSuccess: () async {
          final res = await ApiService.reviewTaskReward(taskId);
          if (res['response'] == 'success') {
            ToastManager.success('Reward claimed successfully!');
            if (context.mounted) Navigator.of(context).pop();
          } else {
            ToastManager.error(
              msg: (res['reason'] ?? res['message'] ?? 'Failed').toString(),
            );
          }
        },
      );

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructionLines = _buildInstructionLines();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppTheme.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: AppTheme.cardShadowMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, AppTheme.warningOrange700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warningOrange600.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      TablerIcons.star,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Review & Earn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete the steps below',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.amber.withOpacity(0.08)
                          : Colors.amber.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      border: Border.all(
                        color: isDark
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.amber.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              TablerIcons.list_check,
                              color: Colors.amber.shade600,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Instructions',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                          instructionLines.isEmpty
                              ? 1
                              : (instructionLines.length * 2 - 1),
                          (i) {
                            if (instructionLines.isEmpty) {
                              return _buildInstructionItem(
                                '1',
                                'Complete the task to claim your reward',
                                isDark,
                              );
                            }
                            if (i.isOdd) return const SizedBox(height: 12);
                            final idx = i ~/ 2;
                            return _buildInstructionItem(
                              '${idx + 1}',
                              instructionLines[idx],
                              isDark,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Important note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.warningOrange.withOpacity(0.08)
                          : AppTheme.warningOrange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.warningOrange.withOpacity(0.2)
                            : AppTheme.warningOrange.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          TablerIcons.info_circle,
                          color: AppTheme.warningOrange400,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete all the steps above to earn $coins coins. The required tasks are mandatory - failing to complete them will not grant the reward.',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.warningOrange200
                                  : AppTheme.warningOrange800,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Launch Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(context, url),
                      icon: const Icon(TablerIcons.brand_google_play, size: 22),
                      label: const Text(
                        'Open Play Store',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.amber.shade700.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.amber.shade800,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
