import 'dart:async';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

class NoInternetPage extends StatefulWidget {
  const NoInternetPage({super.key});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage> {
  Timer? _checkTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Periodically check for internet connection
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkInternetConnection();
    });
    // Initial check
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    final hasInternet = await ConnectivityService.instance
        .hasInternetConnection();

    if (hasInternet && mounted) {
      // Internet restored - go back
      _checkTimer?.cancel();
      Navigator.of(context).pop();
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // No Internet Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TablerIcons.wifi_off,
                    size: 60,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Please check your internet connection and try again.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Tips
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            TablerIcons.bulb,
                            size: 20,
                            color: Colors.amber.shade400,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Try these steps:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTipItem('1', 'Check your Wi-Fi or mobile data'),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        '2',
                        'Turn on Airplane mode and turn it off',
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem('3', 'Restart your router or modem'),
                      const SizedBox(height: 12),
                      _buildTipItem('4', 'Move to an area with better signal'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Loading indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Waiting for connection...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
