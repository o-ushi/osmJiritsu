import 'package:flutter/material.dart';

/// The wizard's single call-to-action per screen: a wide pill button that
/// fades/scales into view once [visible] flips true, so users never see a
/// disabled button — just an empty space until they've done enough to
/// proceed. Keeps every screen down to "one obvious next step".
class PrimaryCtaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool visible;
  final VoidCallback onPressed;

  const PrimaryCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 0.4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
