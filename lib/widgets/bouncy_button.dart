import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../theme.dart';

/// A big, rounded, squishy button. Scales down when pressed and plays
/// a click. Sized for small hands.
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final EdgeInsets padding;
  final bool silent;

  const BouncyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = DumplingTheme.peach,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    this.silent = false,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = HSLColor.fromColor(widget.color)
        .withLightness(
            (HSLColor.fromColor(widget.color).lightness - 0.18).clamp(0, 1))
        .toColor();
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.silent) Sfx.instance.play(Sound.click);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: dark.withValues(alpha: 0.5), width: 3),
            boxShadow: [
              BoxShadow(
                color: dark.withValues(alpha: 0.45),
                offset: Offset(0, _pressed ? 2 : 5),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A round icon button variant, for game controls.
class BouncyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;

  const BouncyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = DumplingTheme.sky,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onPressed: onPressed,
      color: color,
      silent: true,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.55, color: DumplingTheme.ink),
      ),
    );
  }
}
