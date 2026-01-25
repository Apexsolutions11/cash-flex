import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../theme/app_theme.dart';

import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/external_app_model.dart';
import '../theme/app_theme.dart';
import '../utils/helper/jackpot_check_helper.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ExternalAppModal extends StatefulWidget {
  final ExternalAppModel app;

  const ExternalAppModal({super.key, required this.app});

  @override
  State<ExternalAppModal> createState() => _ExternalAppModalState();
}

class _ExternalAppModalState extends State<ExternalAppModal> {
  Future<void> _launchPlayStore(String? url) async {
    if (url == null || url.isEmpty) return;

    // Get current user ID
    final userId = AuthService.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      // If user is not logged in, launch without referrer
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Build referrer parameter: pid=cashflex&ref_id=USER_ID
    final referrerValue = 'pid=cashflex&ref_id=$userId';
    final encodedReferrer = Uri.encodeComponent(referrerValue);

    // Append referrer to URL
    // Check if URL already has query parameters
    final separator = url.contains('?') ? '&' : '?';
    final urlWithReferrer = '$url${separator}referrer=$encodedReferrer';

    final uri = Uri.parse(urlWithReferrer);
    if (await canLaunchUrl(uri)) {
      // Coins will be awarded via postback from the external app
      // No timer-based tracking needed
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppTheme.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: AppTheme.cardShadowMedium,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // App Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // App Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      image: widget.app.photo != null
                          ? DecorationImage(
                              image: NetworkImage(widget.app.photo!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                      color: widget.app.photo == null
                          ? Colors.blue.shade700
                          : null,
                    ),
                    child: widget.app.photo == null
                        ? const Icon(
                            TablerIcons.device_gamepad_2,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // App Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.app.title ?? 'App',
                          style: TextStyle(
                            color: theme.textTheme.titleLarge?.color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              final rating = widget.app.stars ?? 0.0;
                              if (index < rating.floor()) {
                                return const Icon(
                                  TablerIcons.star,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              } else if (index < rating) {
                                return const Icon(
                                  TablerIcons.star_half,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              } else {
                                return Icon(
                                  TablerIcons.star,
                                  size: 16,
                                  color: isDark
                                      ? Colors.grey
                                      : Colors.grey.shade300,
                                );
                              }
                            }),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/images/coin.png',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.app.coins ?? 0}',
                              style: TextStyle(
                                color: theme.textTheme.titleMedium?.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.app.description != null &&
                widget.app.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.app.description!,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Tasks Section
            if (widget.app.tasks != null && widget.app.tasks!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      TablerIcons.list_check,
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tasks to Complete',
                      style: TextStyle(
                        color: theme.textTheme.titleMedium?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.app.tasks!.length,
                  itemBuilder: (context, index) {
                    final task = widget.app.tasks![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey.shade300,
                            ),
                            child: Icon(
                              TablerIcons.circle,
                              size: 16,
                              color: isDark ? Colors.white60 : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Info about postback rewards
            if (widget.app.coins != null && widget.app.coins! > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        TablerIcons.info_circle,
                        color: Colors.blue.shade300,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete all the tasks above to earn ${widget.app.coins} coins. Rewards will be credited automatically after task completion.',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Launch Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final canProceed =
                        await JackpotCheckHelper.checkAndShowDialogIfNeeded(
                          context,
                        );
                    if (!canProceed) return;
                    _launchPlayStore(widget.app.playStoreUrl);
                  },
                  icon: const Icon(TablerIcons.external_link, size: 20),
                  label: Text(
                    widget.app.buttonText ?? 'Open in Play Store',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
