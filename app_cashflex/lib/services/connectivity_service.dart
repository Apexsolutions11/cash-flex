import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../pages/no_internet_page.dart';

class ConnectivityService {
  ConnectivityService._();
  
  static final ConnectivityService instance = ConnectivityService._();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;
  bool _isConnected = true;
  bool _isNoInternetPageShown = false;
  BuildContext? _context;
  
  /// Check if device has internet connection (not just network connectivity)
  Future<bool> hasInternetConnection() async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 3);
      dio.options.receiveTimeout = const Duration(seconds: 3);
      
      // Try to reach a reliable server
      final response = await dio.get('https://www.google.com');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Start listening to connectivity changes
  void startListening(BuildContext context) {
    _context = context;
    _connectivitySubscription?.cancel();
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _handleConnectivityChange();
      },
    );
    
    // Initial check
    _checkInitialConnection();
    
    // Also periodically check (in case connectivity_plus doesn't detect changes)
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _handleConnectivityChange();
    });
  }
  
  Future<void> _handleConnectivityChange() async {
    if (_context == null || !_context!.mounted) return;
    
    // Check if we have actual internet, not just network connectivity
    final hasInternet = await hasInternetConnection();
    
    if (hasInternet != _isConnected) {
      _isConnected = hasInternet;
      
      if (!_isConnected && !_isNoInternetPageShown) {
        // No internet - navigate to no internet page
        _isNoInternetPageShown = true;
        if (_context != null && _context!.mounted) {
          try {
            // Check if Navigator is available
            final navigator = Navigator.maybeOf(_context!);
            if (navigator == null) {
              debugPrint('Navigator not available in context');
              return;
            }
            
            // Check if we're already on no internet page
            final currentRoute = ModalRoute.of(_context!);
            if (currentRoute?.settings.name != '/no-internet') {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const NoInternetPage(),
                  settings: const RouteSettings(name: '/no-internet'),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error navigating to no internet page: $e');
          }
        }
      } else if (_isConnected && _isNoInternetPageShown) {
        // Internet restored - go back
        _isNoInternetPageShown = false;
        if (_context != null && _context!.mounted) {
          try {
            // Check if Navigator is available
            final navigator = Navigator.maybeOf(_context!);
            if (navigator == null) {
              debugPrint('Navigator not available in context');
              return;
            }
            
            // Check if we're on the no internet page
            final currentRoute = ModalRoute.of(_context!);
            if (currentRoute?.settings.name == '/no-internet') {
              navigator.pop();
            }
          } catch (e) {
            debugPrint('Error navigating back from no internet page: $e');
          }
        }
      }
    }
  }
  
  /// Check initial connection status
  Future<void> _checkInitialConnection() async {
    if (_context == null || !_context!.mounted) return;
    
    final hasInternet = await hasInternetConnection();
    _isConnected = hasInternet;
    
    if (!_isConnected && !_isNoInternetPageShown && _context != null && _context!.mounted) {
      _isNoInternetPageShown = true;
      try {
        // Check if Navigator is available
        final navigator = Navigator.maybeOf(_context!);
        if (navigator == null) {
          debugPrint('Navigator not available in context for initial check');
          return;
        }
        
        final currentRoute = ModalRoute.of(_context!);
        if (currentRoute?.settings.name != '/no-internet') {
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const NoInternetPage(),
              settings: const RouteSettings(name: '/no-internet'),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error navigating to no internet page on initial check: $e');
      }
    }
  }
  
  /// Stop listening to connectivity changes
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
    _context = null;
  }
  
  /// Get current connection status
  bool get isConnected => _isConnected;
}

