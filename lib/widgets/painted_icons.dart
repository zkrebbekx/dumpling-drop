import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'dumpling.dart';

/// The in-game icon set, painted in the game's own art style so every
/// platform renders the same picture (emoji fonts do not).
enum GameIcon { steamer, pan, chili, bento, sun, book, dumpling }

class PaintedIcon extends StatelessWidget {
  final GameIcon icon;
  final double size;

  const PaintedIcon(this.icon, {super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(icon),
    );
  }
}

class _IconPainter extends CustomPainter {
  final GameIcon icon;

  _IconPainter(this.icon);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    switch (icon) {
      case GameIcon.steamer:
        _steamer(canvas, c, s);
      case GameIcon.pan:
        _pan(canvas, c, s);
      case GameIcon.chili:
        _chili(canvas, c, s);
      case GameIcon.bento:
        _bento(canvas, c, s);
      case GameIcon.sun:
        _sun(canvas, c, s);
      case GameIcon.book:
        _book(canvas, c, s);
      case GameIcon.dumpling:
        paintDumpling(
          canvas,
          Rect.fromCenter(center: c, width: s, height: s),
          DumplingTheme.lemon,
        );
    }
  }

  void _steamer(Canvas canvas, Offset c, double s) {
    // A bamboo steamer basket with a steam curl.
    final basket = Rect.fromCenter(
        center: c.translate(0, s * 0.14), width: s * 0.92, height: s * 0.52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(basket, Radius.circular(s * 0.12)),
      Paint()..color = DumplingTheme.bamboo,
    );
    // Rim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: c.translate(0, -s * 0.08),
            width: s * 0.98,
            height: s * 0.2),
        Radius.circular(s * 0.1),
      ),
      Paint()..color = DumplingTheme.bambooDark,
    );
    // Slats.
    final slat = Paint()
      ..color = DumplingTheme.bambooDark.withValues(alpha: 0.5)
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.24, 0.0, 0.24]) {
      canvas.drawLine(c.translate(s * dx, s * 0.04),
          c.translate(s * dx, s * 0.32), slat);
    }
    // Steam curl.
    final steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.9);
    final path = Path()
      ..moveTo(c.dx - s * 0.1, c.dy - s * 0.2)
      ..quadraticBezierTo(c.dx - s * 0.24, c.dy - s * 0.32, c.dx - s * 0.08,
          c.dy - s * 0.42)
      ..quadraticBezierTo(
          c.dx + s * 0.06, c.dy - s * 0.5, c.dx, c.dy - s * 0.42);
    canvas.drawPath(path, steam);
  }

  void _pan(Canvas canvas, Offset c, double s) {
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(-s * 0.08, s * 0.08),
          width: s * 0.72,
          height: s * 0.5),
      Paint()..color = const Color(0xFF8B8B94),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(-s * 0.08, s * 0.05),
          width: s * 0.58,
          height: s * 0.36),
      Paint()..color = const Color(0xFF6E6E76),
    );
    canvas.drawLine(
      c.translate(s * 0.24, -s * 0.02),
      c.translate(s * 0.48, -s * 0.18),
      Paint()
        ..strokeWidth = s * 0.11
        ..strokeCap = StrokeCap.round
        ..color = DumplingTheme.bambooDark,
    );
    paintDumpling(
      canvas,
      Rect.fromCenter(
          center: c.translate(-s * 0.08, s * 0.0),
          width: s * 0.32,
          height: s * 0.32),
      DumplingTheme.lemon,
      face: false,
    );
  }

  void _chili(Canvas canvas, Offset c, double s) {
    final body = Path()
      ..moveTo(c.dx - s * 0.05, c.dy - s * 0.28)
      ..quadraticBezierTo(c.dx + s * 0.42, c.dy - s * 0.2, c.dx + s * 0.3,
          c.dy + s * 0.16)
      ..quadraticBezierTo(c.dx + s * 0.18, c.dy + s * 0.46, c.dx - s * 0.26,
          c.dy + s * 0.34)
      ..quadraticBezierTo(c.dx + s * 0.1, c.dy + s * 0.26, c.dx - s * 0.05,
          c.dy - s * 0.28)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE5534B));
    // Stem.
    canvas.drawLine(
      c.translate(-s * 0.04, -s * 0.26),
      c.translate(-s * 0.14, -s * 0.44),
      Paint()
        ..strokeWidth = s * 0.1
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF5E9E4E),
    );
  }

  void _bento(Canvas canvas, Offset c, double s) {
    final box = Rect.fromCenter(center: c, width: s * 0.9, height: s * 0.74);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(s * 0.14)),
      Paint()..color = DumplingTheme.bambooDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box.deflate(s * 0.07), Radius.circular(s * 0.1)),
      Paint()..color = DumplingTheme.cream,
    );
    canvas.drawLine(
      Offset(c.dx, box.top + s * 0.09),
      Offset(c.dx, box.bottom - s * 0.09),
      Paint()
        ..strokeWidth = s * 0.05
        ..color = DumplingTheme.bambooDark,
    );
    paintDumpling(
      canvas,
      Rect.fromCenter(
          center: c.translate(-s * 0.2, 0), width: s * 0.3, height: s * 0.3),
      DumplingTheme.lemon,
      face: false,
    );
    paintDumpling(
      canvas,
      Rect.fromCenter(
          center: c.translate(s * 0.2, 0), width: s * 0.3, height: s * 0.3),
      DumplingTheme.mint,
      face: false,
    );
  }

  void _sun(Canvas canvas, Offset c, double s) {
    final ray = Paint()
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..color = DumplingTheme.star;
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(c + dir * s * 0.34, c + dir * s * 0.48, ray);
    }
    canvas.drawCircle(c, s * 0.26, Paint()..color = DumplingTheme.star);
    canvas.drawCircle(
        c, s * 0.26, Paint()..color = Colors.white.withValues(alpha: 0.25));
  }

  void _book(Canvas canvas, Offset c, double s) {
    // An open book: two pages meeting at the spine.
    final page = Paint()..color = Colors.white;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..color = DumplingTheme.bambooDark;
    final left = Path()
      ..moveTo(c.dx, c.dy - s * 0.18)
      ..quadraticBezierTo(c.dx - s * 0.24, c.dy - s * 0.32, c.dx - s * 0.44,
          c.dy - s * 0.22)
      ..lineTo(c.dx - s * 0.44, c.dy + s * 0.24)
      ..quadraticBezierTo(
          c.dx - s * 0.22, c.dy + s * 0.14, c.dx, c.dy + s * 0.28)
      ..close();
    final right = Path()
      ..moveTo(c.dx, c.dy - s * 0.18)
      ..quadraticBezierTo(c.dx + s * 0.24, c.dy - s * 0.32, c.dx + s * 0.44,
          c.dy - s * 0.22)
      ..lineTo(c.dx + s * 0.44, c.dy + s * 0.24)
      ..quadraticBezierTo(
          c.dx + s * 0.22, c.dy + s * 0.14, c.dx, c.dy + s * 0.28)
      ..close();
    canvas.drawPath(left, page);
    canvas.drawPath(right, page);
    canvas.drawPath(left, outline);
    canvas.drawPath(right, outline);
    // A tiny star sticker on the right page.
    final star = Path();
    final sc = c.translate(s * 0.2, -s * 0.02);
    for (var i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final radius = (i.isEven ? s * 0.09 : s * 0.04);
      final p = sc + Offset(cos(angle), sin(angle)) * radius;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = DumplingTheme.star);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.icon != icon;
}
