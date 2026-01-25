import 'dart:async';
import '../theme/app_theme.dart';
import 'dart:math';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../theme/app_theme.dart';

import '../models/user_data_model.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../services/mintegral_ad_service.dart';
import '../theme/app_theme.dart';
import '../utils/helper/toast_manager.dart';
import '../theme/app_theme.dart';
import '../utils/constant/constant.dart';
import '../theme/app_theme.dart';

enum GameState { start, playing, gameOver }

class FlappyBirdPage extends ConsumerStatefulWidget {
  const FlappyBirdPage({super.key});

  @override
  ConsumerState<FlappyBirdPage> createState() => _FlappyBirdPageState();
}

class _FlappyBirdPageState extends ConsumerState<FlappyBirdPage>
    with SingleTickerProviderStateMixin {
  GameState _gameState = GameState.start;

  // Basket position (0.0 = left, 1.0 = right)
  double _basketX = 0.5;
  double _targetBasketX = 0.5; // Target position for smooth animation

  // Falling coins
  List<Map<String, dynamic>> _coins = [];

  // Caught coin animations
  List<Map<String, dynamic>> _caughtAnimations = [];

  // Game properties
  int _score = 0;
  int _highScore = 0;
  int _missed = 0;
  Timer? _gameTimer;
  Timer? _coinSpawnTimer;
  Timer? _animationTimer;
  Timer? _basketAnimationTimer;
  Timer? _shakeTimer;

  // New: Missed coins animations
  List<Map<String, dynamic>> _missedAnimations = [];

  // Animation controller for basket
  late AnimationController _basketAnimationController;
  double _shakeOffset = 0.0;

  final double _coinSize = 40.0;
  final double _basketSize = 80.0;
  final double _coinSpeed = 3.0;
  final int _maxMissed = 5;
  final double _basketSmoothing = 0.15; // Smoothing factor for movement

  @override
  void initState() {
    super.initState();
    _basketAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _coinSpawnTimer?.cancel();
    _animationTimer?.cancel();
    _basketAnimationTimer?.cancel();
    _shakeTimer?.cancel();
    _basketAnimationController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _basketX = 0.5;
      _targetBasketX = 0.5;
      _score = 0;
      _missed = 0;
      _coins = [];
      _caughtAnimations = [];
      _missedAnimations = [];
      _shakeOffset = 0.0;
    });

    // Start smooth basket animation timer
    _basketAnimationTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (_gameState != GameState.playing) return;

      // Smooth interpolation towards target position
      final diff = _targetBasketX - _basketX;
      if (diff.abs() > 0.001) {
        setState(() {
          _basketX += diff * _basketSmoothing;
          // Clamp to bounds
          _basketX = _basketX.clamp(0.1, 0.9);
        });
      }
    });

    // Spawn coins periodically
    _coinSpawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      if (_gameState == GameState.playing) {
        setState(() {
          _coins.add({
            'x':
                Random().nextDouble() * 0.8 +
                0.1, // Random x position (10% to 90%)
            'y': 0.0,
            'id': DateTime.now().millisecondsSinceEpoch,
          });
        });
      }
    });

    // Game loop
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_gameState != GameState.playing) return;

      setState(() {
        // Update coin positions
        for (var coin in _coins) {
          coin['y'] =
              (coin['y'] as double) +
              (_coinSpeed / MediaQuery.of(context).size.height);
        }

        // Check for catches and misses
        _coins.removeWhere((coin) {
          double coinY = coin['y'] as double;
          double coinX = coin['x'] as double;

          // Check if coin reached bottom
          if (coinY > 0.85) {
            // Check if caught by basket
            double basketLeft =
                _basketX -
                (_basketSize / MediaQuery.of(context).size.width / 2);
            double basketRight =
                _basketX +
                (_basketSize / MediaQuery.of(context).size.width / 2);
            double coinLeft =
                coinX - (_coinSize / MediaQuery.of(context).size.width / 2);
            double coinRight =
                coinX + (_coinSize / MediaQuery.of(context).size.width / 2);

            if (coinRight > basketLeft && coinLeft < basketRight) {
              // Caught! Add animation
              _caughtAnimations.add({
                'x': coinX,
                'y': coinY - 0.05,
                'opacity': 1.0,
                'scale': 1.0,
                'id': coin['id'],
                'text': '+1',
              });
              _score++;
              _shakeBasket();
              if (_score > _highScore) {
                _highScore = _score;
              }
            } else {
              // Missed!
              _missed++;
              _missedAnimations.add({
                'x': coinX,
                'y': coinY,
                'opacity': 1.0,
                'id': coin['id'],
              });
              if (_missed >= _maxMissed) {
                _endGame();
              }
            }
            return true; // Remove coin
          }
          return false;
        });
      });
    });

    // Animation timer for caught and missed coins
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_gameState != GameState.playing) return;

      setState(() {
        _caughtAnimations.removeWhere((anim) {
          anim['opacity'] = (anim['opacity'] as double) - 0.04;
          anim['scale'] = (anim['scale'] as double) + 0.02;
          anim['y'] = (anim['y'] as double) - 0.005;
          return anim['opacity'] <= 0;
        });

        _missedAnimations.removeWhere((anim) {
          anim['opacity'] = (anim['opacity'] as double) - 0.05;
          anim['y'] = (anim['y'] as double) + 0.01; // Keep falling
          return anim['opacity'] <= 0;
        });
      });
    });
  }

  void _shakeBasket() {
    _shakeTimer?.cancel();
    int count = 0;
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() {
        _shakeOffset = (count % 2 == 0) ? 5.0 : -5.0;
      });
      count++;
      if (count > 6) {
        timer.cancel();
        setState(() {
          _shakeOffset = 0.0;
        });
      }
    });
  }

  void _endGame() async {
    _gameTimer?.cancel();
    _coinSpawnTimer?.cancel();
    _animationTimer?.cancel();
    _basketAnimationTimer?.cancel();
    setState(() {
      _gameState = GameState.gameOver;
    });

    // Increment game count
    try {
      await ApiService.incrementGameCount();
      ref.invalidate(currentUserProvider);
    } catch (e) {
      debugPrint('Error incrementing game count: $e');
    }

    // Show interstitial ad after game ends
    if (MintegralAdService.isInitialized) {
      try {
        await MintegralAdService.showInterstitialAd();
      } catch (e) {
        debugPrint('Error showing interstitial ad: $e');
      }
    }

    _showResultDialog();
  }

  void _moveBasket(double deltaX) {
    if (_gameState == GameState.playing) {
      // Update target position instead of direct position
      final newTargetX = (_targetBasketX + deltaX).clamp(0.1, 0.9);

      // Only update if not at boundary or moving away from boundary
      if (newTargetX != _targetBasketX) {
        _targetBasketX = newTargetX;
        // Don't call setState here - let the animation timer handle it
      }
    }
  }

  void _showResultDialog() {
    final userAsync = ref.read(currentUserProvider);
    int dailyGameCount = 0;
    userAsync.when(
      data: (user) => dailyGameCount = user?.dailyGameCount ?? 0,
      loading: () => dailyGameCount = 0,
      error: (_, __) => dailyGameCount = 0,
    );
    final gameLimit = dailyGameLimit;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        score: _score,
        highScore: _highScore,
        dailyGameCount: dailyGameCount,
        dailyGameLimit: gameLimit,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _startGame();
        },
        onExit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(TablerIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Catch the Coins',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildUserStatusChips(userAsync),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildUserStatusChips(AsyncValue<UserDataModel?> userAsync) {
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/coin.png', width: 16, height: 16),
              const SizedBox(width: 4),
              Text(
                '${user.coins}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBody() {
    if (_gameState == GameState.start) {
      return _buildStartScreen();
    }
    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF60A5FA).withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Game Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/coin.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Catch the Coins',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'High Score: $_highScore',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'How to Play',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInstructionItem(
                          '1',
                          'Tap left/right to move the basket',
                          const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem(
                          '2',
                          'Catch falling coins to score points',
                          const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem(
                          '3',
                          'Avoid missing coins (max 5 misses)',
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionItem(
                          '4',
                          'Score as many points as you can!',
                          const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Start Button
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AppTheme.buildGradientButton(
                      onPressed: _startGame,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: const Text(
                        'Start Game',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
          ),
        ),
      ],
    );
  }

  Widget _buildGameScreen() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        double screenWidth = MediaQuery.of(context).size.width;
        double deltaX = details.delta.dx / screenWidth;
        _moveBasket(deltaX);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF87CEEB),
              const Color(0xFF87CEEB).withOpacity(0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Falling coins
            ..._coins.map((coin) => _buildCoin(coin)),
            // Caught coin animations (Now just a pop effect, no coin image)
            ..._caughtAnimations.map((anim) => _buildCaughtAnimation(anim)),
            // Missed coin animations
            ..._missedAnimations.map((anim) => _buildMissedAnimation(anim)),
            // Drag Track / Guide
            Positioned(
              bottom: 45,
              left: 20,
              right: 20,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        TablerIcons.arrows_left_right,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DRAG TO MOVE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Basket
            _buildBasket(),
            // Score and misses
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Text(
                      'Score: $_score',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Text(
                      'Missed: $_missed/$_maxMissed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _missed >= _maxMissed - 1
                            ? Colors.red
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoin(Map<String, dynamic> coin) {
    return Positioned(
      left:
          (coin['x'] as double) * MediaQuery.of(context).size.width -
          _coinSize / 2,
      top: (coin['y'] as double) * MediaQuery.of(context).size.height,
      child: Image.asset(
        'assets/images/coin.png',
        width: _coinSize,
        height: _coinSize,
      ),
    );
  }

  Widget _buildBasket() {
    final screenWidth = MediaQuery.of(context).size.width;
    final basketLeft = _basketX * screenWidth - _basketSize / 2;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
      bottom: 40, // Repositioned to bottom
      left: basketLeft + _shakeOffset,
      child: Container(
        width: _basketSize,
        height: _basketSize * 0.6,
        decoration: BoxDecoration(
          color: const Color(0xFF8B4513),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF654321), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(TablerIcons.basket, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildCaughtAnimation(Map<String, dynamic> anim) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final animX = anim['x'] as double;
    final animY = anim['y'] as double;
    final animScale = anim['scale'] as double;
    final animOpacity = anim['opacity'] as double;

    return Positioned(
      left: animX * screenWidth - 50,
      top: animY * screenHeight - 20,
      child: Opacity(
        opacity: animOpacity,
        child: Transform.scale(
          scale: animScale,
          child: Column(
            children: [
              const Text(
                '+1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissedAnimation(Map<String, dynamic> anim) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final animX = anim['x'] as double;
    final animY = anim['y'] as double;
    final animOpacity = anim['opacity'] as double;

    return Positioned(
      left: animX * screenWidth - _coinSize / 2,
      top: animY * screenHeight,
      child: Opacity(
        opacity: animOpacity,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.redAccent,
            BlendMode.modulate,
          ),
          child: Image.asset(
            'assets/images/coin.png',
            width: _coinSize,
            height: _coinSize,
          ),
        ),
      ),
    );
  }
}

class _ResultDialog extends ConsumerStatefulWidget {
  final int score;
  final int highScore;
  final int dailyGameCount;
  final int dailyGameLimit;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _ResultDialog({
    required this.score,
    required this.highScore,
    required this.dailyGameCount,
    required this.dailyGameLimit,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  ConsumerState<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends ConsumerState<_ResultDialog> {
  bool _hasClaimed = false;
  bool _isClaiming = false;

  Future<void> _claimCoins() async {
    if (_isClaiming || _hasClaimed) return;

    setState(() => _isClaiming = true);

    try {
      final coins = _calculateCoins();
      if (coins <= 0) {
        // No coins to claim, just restart the game
        if (mounted) {
          Navigator.of(context).pop();
          widget.onPlayAgain();
        }
        return;
      }

      // Show interstitial ad
      final adShown = await MintegralAdService.showInterstitialAd();

      if (adShown) {
        // Award coins after ad is shown
        await ApiService.claimCoins(coins, 'CATCH_COINS');
        ref.invalidate(currentUserProvider);

        if (mounted) {
          ToastManager.success('Congratulations! You earned $coins coins! 🎉');
        }

        setState(() => _hasClaimed = true);

        // Automatically restart the game after a short delay
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop();
          widget.onPlayAgain();
        }
      } else {
        // Ad failed - silently close dialog and reset game without rewarding coins or showing error
        if (mounted) {
          Navigator.of(context).pop();
          widget.onPlayAgain();
        }
      }
    } catch (e) {
      debugPrint('Error claiming coins: $e');
      // Ad failed - silently close dialog and reset game without rewarding coins or showing error
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPlayAgain();
      }
    }
  }

  int _calculateCoins() {
    if (widget.score == 0) return 0;
    if (widget.score < 10) return 5;
    if (widget.score < 20) return 10;
    if (widget.score < 30) return 15;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coins = _calculateCoins();
    final isNewHighScore = widget.score == widget.highScore && widget.score > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isNewHighScore
                    ? const Color(0xFFFBBF24).withOpacity(0.1)
                    : const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNewHighScore ? TablerIcons.trophy : TablerIcons.coin,
                size: 48,
                color: isNewHighScore
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              isNewHighScore ? 'New High Score!' : 'Game Over',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow('Score', '${widget.score}'),
                  const SizedBox(height: 12),
                  _buildStatRow('High Score', '${widget.highScore}'),
                  if (coins > 0) ...[
                    const SizedBox(height: 12),
                    _buildStatRow('Coins Earned', '+$coins'),
                  ],
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Games Today',
                    '${widget.dailyGameCount}/${widget.dailyGameLimit}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Show "Claim Coins" button only if coins > 0 and not claimed yet
            if (coins > 0 && !_hasClaimed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isClaiming ? null : _claimCoins,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isClaiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/coin.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Claim $coins Coins',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ] else if (coins == 0) ...[
              // If no coins, show play again button
              SizedBox(
                width: double.infinity,
                child: AppTheme.buildGradientButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onPlayAgain();
                  },
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
