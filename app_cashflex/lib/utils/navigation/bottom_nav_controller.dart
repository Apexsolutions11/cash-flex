import 'package:flutter/material.dart';

/// Controller for the app's bottom navigation index.
class BottomNavController extends ValueNotifier<int> {
  BottomNavController([super.value = 0]);

  void goTo(int index) => value = index;

  void goToWallet() => value = 3;
}

/// Makes a [BottomNavController] available down the widget tree.
class BottomNavScope extends InheritedNotifier<BottomNavController> {
  const BottomNavScope({
    super.key,
    required BottomNavController controller,
    required super.child,
  }) : super(notifier: controller);

  static BottomNavController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BottomNavScope>()
        ?.notifier;
  }

  static BottomNavController of(BuildContext context) {
    final c = maybeOf(context);
    assert(c != null, 'BottomNavScope not found in the widget tree.');
    return c!;
  }
}
