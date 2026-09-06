import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../theme.dart';

/// A big, rounded, squishy button. Scales down when pressed and plays
/// a click. Sized for small hands.
///
/// With [repeat], the button fires on press and keeps firing while
/// held — for the move buttons, so crossing the board is one hold,
/// not nine taps.
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final EdgeInsets padding;
  final bool silent;
  final bool repeat;
  final String? semanticLabel;

  const BouncyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = DumplingTheme.peach,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    this.silent = false,
    this.repeat = false,
    this.semanticLabel,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  bool _pressed = false;
  Timer? _holdDelay;
  Timer? _holdRepeat;

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  void _cancelHold() {
    _holdDelay?.cancel();
    _holdRepeat?.cancel();
  }

  void _down() {
    setState(() => _pressed = true);
    if (!widget.repeat) return;
    widget.onPressed();
    _holdDelay = Timer(const Duration(milliseconds: 300), () {
      _holdRepeat = Timer.periodic(
        const Duration(milliseconds: 130),
        (_) => widget.onPressed(),
      );
    });
  }

  void _up({required bool fire}) {
    setState(() => _pressed = false);
    _cancelHold();
    if (widget.repeat || !fire) return;
    if (!widget.silent) Sfx.instance.play(Sound.click);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final dark = HSLColor.fromColor(widget.color)
        .withLightness(
            (HSLColor.fromColor(widget.color).lightness - 0.18).clamp(0, 1))
        .toColor();
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _down(),
        onTapCancel: () => _up(fire: false),
        onTapUp: (_) => _up(fire: true),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(26),
              border:
                  Border.all(color: dark.withValues(alpha: 0.5), width: 3),
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
  final bool repeat;
  final String? label;

  const BouncyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = DumplingTheme.sky,
    this.size = 64,
    this.repeat = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onPressed: onPressed,
      color: color,
      silent: true,
      repeat: repeat,
      semanticLabel: label,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.55, color: DumplingTheme.ink),
      ),
    );
  }
}
