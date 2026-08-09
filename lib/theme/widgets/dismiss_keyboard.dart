import 'package:flutter/material.dart';

/// Dismisses the soft keyboard when the user taps outside a focused field.
///
/// Wrap at the [MaterialApp.builder] level so every screen gets the behavior
/// without repeating [GestureDetector] on each scaffold.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
