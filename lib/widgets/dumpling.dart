import 'dart:math';

import 'package:flutter/material.dart';

Color shade(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

/// Paints one squishy dumpling inside [rect].
///
/// [squish] 0..1 flattens the dumpling, for landing wobbles.
/// [eyeOpen] 0..1 closes the eyes, for blinking.
/// [eyeShift] moves the pupils, as a fraction of the body size, so a
/// falling dumpling can watch where it lands.
/// [lean] tilts the dumpling (radians) around its bottom center, for
/// a jelly wobble while moving sideways.
void paintDumpling(
  Canvas canvas,
  Rect rect,
  Color color, {
  double squish = 0,
  bool face = true,
  double eyeOpen = 1,
  double alpha = 1,
  Offset eyeShift = Offset.zero,
  double lean = 0,
}) {
  canvas.save();

  if (lean != 0) {
    final cx = rect.center.dx;
    final bottom = rect.bottom;
    canvas.translate(cx, bottom);
    canvas.rotate(lean);
    canvas.translate(-cx, -bottom);
  }

  // Squish: press down toward the bottom of the cell.
  if (squish > 0) {
    final cx = rect.center.dx;
    final bottom = rect.bottom;
    canvas.translate(cx, bottom);
    canvas.scale(1 + 0.18 * squish, 1 - 0.22 * squish);
    canvas.translate(-cx, -bottom);
  }

  final body = Rect.fromCenter(
    center: rect.center.translate(0, rect.height * 0.04),
    width: rect.width * 0.94,
    height: rect.height * 0.9,
  );
  final radius = Radius.circular(rect.width * 0.42);
  final rrect = RRect.fromRectAndRadius(body, radius);

  final light = shade(color, 0.12);
  final dark = shade(color, -0.18);

  // Body with a soft top-light gradient.
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        light.withValues(alpha: alpha),
        color.withValues(alpha: alpha),
      ],
    ).createShader(body);
  canvas.drawRRect(rrect, paint);

  // Outline.
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, rect.width * 0.045)
      ..color = dark.withValues(alpha: 0.55 * alpha),
  );

  // Pleats: three little folds at the top, like a pinched wrapper.
  final pleatPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = max(1.0, rect.width * 0.05)
    ..color = dark.withValues(alpha: 0.5 * alpha);
  final topY = body.top + body.height * 0.16;
  final cx = body.center.dx;
  final spread = body.width * 0.16;
  for (var i = -1; i <= 1; i++) {
    final x = cx + i * spread;
    final path = Path()
      ..moveTo(x - spread * 0.3, topY + body.height * 0.08)
      ..quadraticBezierTo(
        x,
        topY - body.height * 0.06,
        x + spread * 0.3,
        topY + body.height * 0.08,
      );
    canvas.drawPath(path, pleatPaint);
  }

  if (face) {
    final faceColor = const Color(0xFF5B4636).withValues(alpha: 0.85 * alpha);
    final eyeY = body.center.dy +
        body.height * 0.05 +
        eyeShift.dy * body.height;
    final eyeDx = body.width * 0.18;
    final eyeR = max(1.2, body.width * 0.055);
    final cxShifted = cx + eyeShift.dx * body.width;

    if (eyeOpen > 0.3) {
      canvas.drawCircle(Offset(cxShifted - eyeDx, eyeY), eyeR,
          Paint()..color = faceColor);
      canvas.drawCircle(Offset(cxShifted + eyeDx, eyeY), eyeR,
          Paint()..color = faceColor);
    } else {
      // Happy closed eyes.
      final closed = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = eyeR * 0.9
        ..color = faceColor;
      for (final side in [-1, 1]) {
        final ex = cx + side * eyeDx;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(ex, eyeY), radius: eyeR * 1.4),
          pi * 1.15,
          pi * 0.7,
          false,
          closed,
        );
      }
    }

    // Smile.
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cx, eyeY + body.height * 0.1),
        radius: body.width * 0.1,
      ),
      pi * 0.15,
      pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(1.2, body.width * 0.045)
        ..color = faceColor,
    );

    // Blush.
    final blush = Paint()
      ..color = const Color(0xFFFF8FA3).withValues(alpha: 0.4 * alpha);
    canvas.drawCircle(
        Offset(cx - eyeDx * 1.65, eyeY + body.height * 0.09),
        body.width * 0.07,
        blush);
    canvas.drawCircle(
        Offset(cx + eyeDx * 1.65, eyeY + body.height * 0.09),
        body.width * 0.07,
        blush);
  }

  canvas.restore();
}

/// A single big animated dumpling: bounces gently and blinks.
/// Used as the game mascot on menus.
class DumplingMascot extends StatefulWidget {
  final double size;
  final Color color;

  const DumplingMascot({
    super.key,
    this.size = 120,
    this.color = const Color(0xFFFFE49C),
  });

  @override
  State<DumplingMascot> createState() => _DumplingMascotState();
}

class _DumplingMascotState extends State<DumplingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return CustomPaint(
        size: Size.square(widget.size),
        painter: _MascotPainter(
            color: widget.color, squish: 0.1, eyeOpen: 1),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final bounce = sin(t * 2 * pi) * 0.5 + 0.5;
        // Blink briefly once per cycle.
        final blink = (t > 0.82 && t < 0.9) ? 0.0 : 1.0;
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _MascotPainter(
            color: widget.color,
            squish: bounce * 0.25,
            eyeOpen: blink,
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  final Color color;
  final double squish;
  final double eyeOpen;

  _MascotPainter({
    required this.color,
    required this.squish,
    required this.eyeOpen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintDumpling(
      canvas,
      Offset.zero & size,
      color,
      squish: squish,
      eyeOpen: eyeOpen,
    );
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.squish != squish || old.eyeOpen != eyeOpen || old.color != color;
}
