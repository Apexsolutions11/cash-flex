import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LeaderboardTimer extends HookWidget {
  const LeaderboardTimer({
    super.key,
    required this.leaderboardTimeLeft,
  });

  final int leaderboardTimeLeft;

  @override
  Widget build(BuildContext context) {
    final elapsedMs = useState(
      leaderboardTimeLeft == 0
          ? 0
          : leaderboardTimeLeft - DateTime.now().millisecondsSinceEpoch,
    );

    Timer? timer;
    if (leaderboardTimeLeft > 0) {
      timer = useMemoized(
        () => Timer.periodic(const Duration(seconds: 1), (timer) {
          elapsedMs.value -= 1000;
        }),
      );
      useEffect(() => () => timer?.cancel(), [timer]);
    }

    final int hours = (elapsedMs.value ~/ 3600000) % 24;
    final int minutes = (elapsedMs.value ~/ 60000) % 60;
    final int seconds = (elapsedMs.value ~/ 1000) % 60;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlipOdometerDigit(digit: (hours ~/ 10) % 10, label: 'h'),
              FlipOdometerDigit(digit: hours % 10, label: 'h'),
              _buildColon(),
              FlipOdometerDigit(digit: (minutes ~/ 10) % 10, label: 'm'),
              FlipOdometerDigit(digit: minutes % 10, label: 'm'),
              _buildColon(),
              FlipOdometerDigit(digit: (seconds ~/ 10) % 10, label: 's'),
              FlipOdometerDigit(digit: seconds % 10, label: 's'),
            ],
          ),
        ],
      ),
    );
  }

  Padding _buildColon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          const Text(
            ':',
            style: TextStyle(
              fontSize: 24,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class FlipOdometerDigit extends HookWidget {
  final int digit;
  final String label;

  const FlipOdometerDigit({
    super.key,
    required this.digit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 400),
    )..forward();

    final curvedAnimation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    final animation = useAnimation(
        Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation));
    final previousDigit = usePrevious(digit) ?? digit;

    useEffect(() {
      if (previousDigit != digit) controller.forward(from: 0.0);
      return;
    }, [digit]);

    return Column(
      children: [
        Container(
          width: 30,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(animation * 3.14),
                  alignment: Alignment.center,
                  child: animation <= 0.5
                      ? _buildDigit(previousDigit)
                      : Transform(
                          transform: Matrix4.identity()..rotateX(3.14),
                          alignment: Alignment.center,
                          child: _buildDigit(digit),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildDigit(int digit) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '$digit',
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

T? usePrevious<T>(T value) {
  final ref = useRef<T?>(null);
  final previous = ref.value;
  useEffect(() {
    ref.value = value;
    return null;
  }, [value]);
  return previous;
}

