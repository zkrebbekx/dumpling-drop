import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A cozy animated background: soft steam puffs drift upward forever.
class SteamBackground extends StatefulWidget {
  final Widget child;

  const SteamBackground({super.key, required this.child});

  @override
  State<SteamBackground> createState() => _SteamBackgroundState();
}

class _SteamBackgroundState extends State<SteamBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honor the platform reduced-motion setting: skip the drifting
    // steam and keep the calm gradient.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [DumplingTheme.cream, DumplingTheme.creamDark],
            ),
          ),
        ),
        if (!reduceMotion)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _SteamPainter(_controller.value),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _SteamPainter extends CustomPainter {
  final double t;

  _SteamPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(11);
    for (var i = 0; i < 10; i++) {
      final speed = 0.5 + random.nextDouble();
      final phase = random.nextDouble();
      final x = random.nextDouble() * size.width +
          sin((t * 2 * pi * speed) + i) * 30;
      final progress = ((t * speed + phase) % 1.0);
      final y = size.height * (1.1 - progress * 1.3);
      final radius = 24 + random.nextDouble() * 42;
      final alpha = (0.10 * sin(progress * pi)).clamp(0.0, 0.10);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  @override
  bool shouldRepaint(_SteamPainter old) => old.t != t;
}
