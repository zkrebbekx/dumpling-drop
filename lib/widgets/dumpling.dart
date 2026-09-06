import 'dart:math';

import 'package:flutter/material.dart';

import '../game/piece.dart';

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
/// [kind] adds that character's signature features: Mei's unicorn
/// horn and rainbow mane, Gyo's flame, Ube's glitter stars, Po's
/// sunglasses, Eda's sprout, and Veg's ninja band.
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
  PieceKind? kind,
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

    if (kind == PieceKind.po) {
      // Po is too cool for eyes: sunglasses, always on.
      final glassPaint = Paint()
        ..color = const Color(0xFF35404D).withValues(alpha: 0.9 * alpha);
      for (final side in [-1, 1]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + side * eyeDx, eyeY),
                width: eyeR * 4.4,
                height: eyeR * 3.2),
            Radius.circular(eyeR * 1.4),
          ),
          glassPaint,
        );
      }
      canvas.drawLine(
        Offset(cx - eyeDx + eyeR * 2.2, eyeY),
        Offset(cx + eyeDx - eyeR * 2.2, eyeY),
        Paint()
          ..strokeWidth = eyeR * 0.8
          ..color = glassPaint.color,
      );
      // A shine dot on the left lens.
      canvas.drawCircle(
        Offset(cx - eyeDx - eyeR * 0.8, eyeY - eyeR * 0.7),
        eyeR * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.55 * alpha),
      );
    } else if (eyeOpen > 0.3) {
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

  if (kind != null && face) {
    _paintFeatures(canvas, body, kind, alpha);
  }

  canvas.restore();
}

/// Signature features per character, drawn inside the body transform
/// so they squish and lean with the dumpling.
void _paintFeatures(Canvas canvas, Rect body, PieceKind kind, double alpha) {
  final cx = body.center.dx;
  final top = body.top;
  final w = body.width;

  switch (kind) {
    case PieceKind.po:
    case PieceKind.bao:
      break; // Po's shades are drawn with the face; Bao is a classic.

    case PieceKind.mei:
      // Rainbow mane: three arcs sweeping off the left side.
      final maneColors = [
        const Color(0xFFF06A6A),
        const Color(0xFFF7C948),
        const Color(0xFF6FB7E8),
      ];
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(cx - w * 0.3, top + w * 0.16),
            radius: w * (0.30 - i * 0.075),
          ),
          pi * 0.75,
          pi * 0.85,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = max(1.0, w * 0.06)
            ..color = maneColors[i].withValues(alpha: 0.95 * alpha),
        );
      }
      // Golden unicorn horn.
      final horn = Path()
        ..moveTo(cx - w * 0.07, top + w * 0.06)
        ..lineTo(cx + w * 0.07, top + w * 0.06)
        ..lineTo(cx + w * 0.005, top - w * 0.22)
        ..close();
      canvas.drawPath(
          horn,
          Paint()
            ..color = const Color(0xFFF2C14E).withValues(alpha: alpha));
      canvas.drawLine(
        Offset(cx - w * 0.03, top),
        Offset(cx + w * 0.045, top - w * 0.06),
        Paint()
          ..strokeWidth = max(0.8, w * 0.03)
          ..color = Colors.white.withValues(alpha: 0.7 * alpha),
      );

    case PieceKind.edamame:
      // A fresh sprout: stem plus two leaves.
      final stem = Paint()
        ..strokeWidth = max(1.0, w * 0.05)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF4E9B5E).withValues(alpha: alpha);
      canvas.drawLine(Offset(cx, top + w * 0.04),
          Offset(cx, top - w * 0.12), stem);
      final leaf = Paint()
        ..color = const Color(0xFF6FBF73).withValues(alpha: alpha);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - w * 0.11, top - w * 0.15),
              width: w * 0.2,
              height: w * 0.12),
          leaf);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + w * 0.11, top - w * 0.15),
              width: w * 0.2,
              height: w * 0.12),
          leaf);

    case PieceKind.gyoza:
      // A little flame tuft, one hundred percent real.
      final flame = Path()
        ..moveTo(cx, top - w * 0.24)
        ..quadraticBezierTo(
            cx + w * 0.14, top - w * 0.08, cx + w * 0.08, top + w * 0.05)
        ..quadraticBezierTo(cx, top + w * 0.1, cx - w * 0.08, top + w * 0.05)
        ..quadraticBezierTo(cx - w * 0.14, top - w * 0.08, cx, top - w * 0.24)
        ..close();
      canvas.drawPath(
          flame,
          Paint()
            ..color = const Color(0xFFF2913D).withValues(alpha: alpha));
      canvas.drawCircle(
          Offset(cx, top - w * 0.02),
          w * 0.06,
          Paint()
            ..color = const Color(0xFFFFE49C).withValues(alpha: alpha));

    case PieceKind.ube:
      // Glitter stars dusted on the body.
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * alpha);
      _tinyStar(canvas, Offset(cx - w * 0.3, body.top + w * 0.34),
          w * 0.07, starPaint);
      _tinyStar(canvas, Offset(cx + w * 0.32, body.top + w * 0.5),
          w * 0.055, starPaint);
      _tinyStar(
          canvas,
          Offset(cx + w * 0.22, body.top + w * 0.18),
          w * 0.045,
          Paint()
            ..color =
                const Color(0xFFF2C14E).withValues(alpha: 0.9 * alpha));

    case PieceKind.veggie:
      // Ninja headband with flying knot tails.
      final bandColor =
          const Color(0xFF3E6B2F).withValues(alpha: 0.9 * alpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, top + w * 0.2),
              width: w * 0.96,
              height: w * 0.14),
          Radius.circular(w * 0.07),
        ),
        Paint()..color = bandColor,
      );
      final tail = Paint()
        ..strokeWidth = max(1.0, w * 0.07)
        ..strokeCap = StrokeCap.round
        ..color = bandColor;
      canvas.drawLine(Offset(cx + w * 0.44, top + w * 0.2),
          Offset(cx + w * 0.62, top + w * 0.06), tail);
      canvas.drawLine(Offset(cx + w * 0.46, top + w * 0.22),
          Offset(cx + w * 0.64, top + w * 0.3), tail);
  }
}

void _tinyStar(Canvas canvas, Offset center, double r, Paint paint) {
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final angle = -pi / 2 + i * pi / 4;
    final radius = i.isEven ? r : r * 0.4;
    final p = center + Offset(cos(angle), sin(angle)) * radius;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(path..close(), paint);
}

/// A single big animated dumpling: bounces gently and blinks.
/// Used as the game mascot on menus. Give it a [kind] to show that
/// character with its signature features and color.
class DumplingMascot extends StatefulWidget {
  final double size;
  final Color color;
  final PieceKind? kind;

  const DumplingMascot({
    super.key,
    this.size = 120,
    this.color = const Color(0xFFFFE49C),
    this.kind,
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

  Color get _color {
    final kind = widget.kind;
    if (kind == null) return widget.color;
    return DumplingBodyColors.of(kind);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return CustomPaint(
        size: Size.square(widget.size),
        painter: _MascotPainter(
            color: _color, squish: 0.1, eyeOpen: 1, kind: widget.kind),
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
            color: _color,
            squish: bounce * 0.25,
            eyeOpen: blink,
            kind: widget.kind,
          ),
        );
      },
    );
  }
}

/// Body colors per character, shared so mascots and board cells match.
abstract final class DumplingBodyColors {
  static const _fillings = <Color>[
    Color(0xFF9ED4F5), // po
    Color(0xFFFFE49C), // bao
    Color(0xFFFFC2D4), // mei
    Color(0xFFA8E6CF), // edamame
    Color(0xFFFFB48A), // gyoza
    Color(0xFFCCB8F0), // ube
    Color(0xFFC5E08B), // veggie
  ];

  static Color of(PieceKind kind) => _fillings[kind.index];
}

class _MascotPainter extends CustomPainter {
  final Color color;
  final double squish;
  final double eyeOpen;
  final PieceKind? kind;

  _MascotPainter({
    required this.color,
    required this.squish,
    required this.eyeOpen,
    this.kind,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Leave headroom so horns and flames are not clipped.
    final rect = Rect.fromLTWH(
        size.width * 0.08, size.height * 0.16,
        size.width * 0.84, size.height * 0.84);
    paintDumpling(
      canvas,
      rect,
      color,
      squish: squish,
      eyeOpen: eyeOpen,
      kind: kind,
    );
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.squish != squish ||
      old.eyeOpen != eyeOpen ||
      old.color != color ||
      old.kind != kind;
}
