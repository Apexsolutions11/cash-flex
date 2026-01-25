import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../pages/follow_and_earn_page.dart';
import '../../utils/constant/constant.dart';
import '../../theme/app_theme.dart';

class HowToEarnFollowUsCard extends StatelessWidget {
  const HowToEarnFollowUsCard({super.key});

  Uri? _normalizeHowToEarnUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // If admin provides just the 11-char YouTube video ID.
    final idOnly = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idOnly.hasMatch(trimmed)) {
      return Uri.parse('https://www.youtube.com/watch?v=$trimmed');
    }

    // If no scheme, assume https.
    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }

  Future<void> _openHowToEarnYoutube(BuildContext context) async {
    final raw = howToEarnYoutubeUrl.trim();
    final uri = _normalizeHowToEarnUri(raw);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('How to earn link is not configured.')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the How to earn link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.paddingHorizontalMedium,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient1,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                boxShadow: AppTheme.cardShadowSmall,
              ),
              child: ElevatedButton.icon(
                onPressed: () => _openHowToEarnYoutube(context),
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text('Watch & Earn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMediumSmall),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient2,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                boxShadow: AppTheme.cardShadowSmall,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FollowAndEarnPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text('Follow & Earn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
