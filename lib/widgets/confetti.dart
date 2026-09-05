import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A full-screen confetti burst. Plays once for about three seconds.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _Flake {
  final double x; // 0..1 across the screen
  final double speed;
  final double drift;
  final double size;
  final double spin;
  final Color color;
  final double delay;

  _Flake(Random r)
      : x = r.nextDouble(),
        speed = 0.55 + r.nextDouble() * 0.7,
        drift = (r.nextDouble() - 0.5) * 0.3,
        size = 7 + r.nextDouble() * 8,
        spin = (r.nextDouble() - 0.5) * 10,
        color = const [
          DumplingTheme.peach,
          DumplingTheme.mint,
          DumplingTheme.sky,
          DumplingTheme.lemon,
          DumplingTheme.pink,
          DumplingTheme.lilac,
          DumplingTheme.star,
        ][r.nextInt(7)],
        delay = r.nextDouble() * 0.4;
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Flake> _flakes;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _flakes = List.generate(90, (_) => _Flake(random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_flakes, _controller.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double t;

  _ConfettiPainter(this.flakes, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final flake in flakes) {
      final local = ((t - flake.delay) / (1 - flake.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = local * flake.speed * (size.height + 100) - 50;
      final x =
          (flake.x + sin(local * 6 + flake.spin) * 0.03 + flake.drift * local) *
              size.width;
      final alpha = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * flake.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero,
              width: flake.size,
              height: flake.size * 0.65),
          const Radius.circular(2),
        ),
        Paint()..color = flake.color.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
