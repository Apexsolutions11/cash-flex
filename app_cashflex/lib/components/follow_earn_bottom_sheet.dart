import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/background_task_gate.dart';
import '../services/api_service.dart';
import '../utils/helper/toast_manager.dart';
import '../utils/constant/constant.dart';
import '../theme/app_theme.dart';

class FollowEarnBottomSheet extends StatelessWidget {
  final String url;
  final String socialName;
  final int coins;
  final int minBackgroundTime;
  final String taskId;

  const FollowEarnBottomSheet({
    super.key,
    required this.url,
    required this.socialName,
    required this.coins,
    required this.minBackgroundTime,
    required this.taskId,
  });

  String _applyTemplate(String input) {
    var out = input;
    out = out.replaceAll('{name}', socialName);
    out = out.replaceAll('{coins}', coins.toString());
    out = out.replaceAll('{seconds}', minBackgroundTime.toString());
    return out;
  }

  List<String> _buildInstructionLines() {
    final template = followTaskInstructions.trim();
    final lines = template.isEmpty
        ? <String>[
            'Click the button below to open {name}',
            'Follow our account on {name}',
            'Stay on {name} for at least {seconds} seconds',
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
      // Gate reward behind background time, then call backend reward endpoint.
      BackgroundTaskGate.instance.start(
        minimumBackgroundTime: minBackgroundTime,
        context: context,
        onSuccess: () async {
          final res = await ApiService.followReward(taskId);
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
                        colors: [AppTheme.secondaryCyan, AppTheme.primaryTeal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryCyan.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      TablerIcons.users,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Follow & Earn',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete the steps below',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.primaryTeal.withOpacity(0.08)
                            : AppTheme.primaryTeal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.primaryTeal.withOpacity(0.2)
                              : AppTheme.primaryTeal.withOpacity(0.1),
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
                              color: Colors.blue.shade400,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Instructions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                              return _buildInstructionItem(context,
                                '1',
                                'Complete the task to claim your reward',
                                isDark,
                              );
                            }
                            if (i.isOdd) return const SizedBox(height: 12);
                            final idx = i ~/ 2;
                            return _buildInstructionItem(context,
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
                          color: AppTheme.warningOrange,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete all the steps above to earn $coins coins. The required tasks are mandatory - failing to complete them will not grant the reward.',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.warningOrange.withOpacity(0.7)
                                  : AppTheme.warningOrange,
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
                      icon: const Icon(TablerIcons.external_link, size: 22),
                      label: Text(
                        'Open $socialName',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      style: AppTheme.primaryButtonStyle.copyWith(
                        backgroundColor: WidgetStateProperty.all(AppTheme.secondaryCyan),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
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

  Widget _buildInstructionItem(BuildContext context, String number, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: AppTheme.primaryTeal,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
