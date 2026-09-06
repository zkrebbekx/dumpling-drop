import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'dumpling.dart';

/// Hand-painted sticker medallions. One painting per badge, drawn
/// with the same painter as the game characters, so the Sticker Book
/// matches the game's art instead of platform emoji.
class StickerArt extends StatelessWidget {
  final String badgeId;
  final double size;
  final bool dimmed;

  const StickerArt({
    super.key,
    required this.badgeId,
    this.size = 64,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: CustomPaint(
        size: Size.square(size),
        painter: _StickerPainter(badgeId),
      ),
    );
  }
}

class _StickerPainter extends CustomPainter {
  final String badgeId;

  _StickerPainter(this.badgeId);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);

    // Medallion.
    final bg = switch (badgeId) {
      'golden' => DumplingTheme.star,
      'spice_legend' => DumplingTheme.peach,
      'steam_champ' => DumplingTheme.sky,
      'pan_master' => DumplingTheme.lemon,
      'special' || 'special5' => DumplingTheme.mint,
      _ => DumplingTheme.pink,
    };
    canvas.drawCircle(center, s * 0.48, Paint()..color = bg);
    canvas.drawCircle(
      center,
      s * 0.48,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.04
        ..color = shade(bg, -0.18).withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      center,
      s * 0.40,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    switch (badgeId) {
      case 'first_line':
        _dumpling(canvas, center, s * 0.5, DumplingTheme.lemon);
      case 'double':
        _dumpling(canvas, center.translate(-s * 0.13, 0), s * 0.38,
            DumplingTheme.pink);
        _dumpling(canvas, center.translate(s * 0.13, 0), s * 0.38,
            DumplingTheme.lemon);
      case 'triple':
        _dumpling(canvas, center.translate(-s * 0.17, s * 0.05), s * 0.3,
            DumplingTheme.mint);
        _dumpling(canvas, center.translate(s * 0.17, s * 0.05), s * 0.3,
            DumplingTheme.sky);
        _dumpling(canvas, center.translate(0, -s * 0.12), s * 0.3,
            DumplingTheme.lemon);
      case 'feast':
        for (final (dx, dy, color) in [
          (-0.13, -0.11, DumplingTheme.lemon),
          (0.13, -0.11, DumplingTheme.mint),
          (-0.13, 0.13, DumplingTheme.sky),
          (0.13, 0.13, DumplingTheme.lilac),
        ]) {
          _dumpling(canvas, center.translate(s * dx, s * dy), s * 0.28,
              color);
        }
      case 'combo3':
        _flame(canvas, center.translate(0, -s * 0.16), s * 0.34);
        _dumpling(canvas, center.translate(0, s * 0.07), s * 0.42,
            DumplingTheme.lemon);
      case 'score3k':
        _chopsticks(canvas, center, s);
        _dumpling(canvas, center, s * 0.42, DumplingTheme.peach);
      case 'lines50':
        _dumpling(canvas, center.translate(0, s * 0.06), s * 0.44,
            DumplingTheme.lemon);
        _chefHat(canvas, center.translate(0, -s * 0.17), s * 0.34);
      case 'lines200':
        _dumpling(canvas, center.translate(0, s * 0.08), s * 0.42,
            DumplingTheme.lemon);
        _chefHat(canvas, center.translate(0, -s * 0.14), s * 0.32);
        _star(canvas, center.translate(s * 0.26, -s * 0.24), s * 0.09);
      case 'games10':
        _dumpling(canvas, center.translate(0, s * 0.06), s * 0.44,
            DumplingTheme.pink);
        _heart(canvas, center.translate(0, -s * 0.24), s * 0.13);
      case 'star3':
        _star(canvas, center.translate(0, -s * 0.02), s * 0.36,
            color: Colors.white.withValues(alpha: 0.85));
        _dumpling(canvas, center.translate(0, s * 0.06), s * 0.4,
            DumplingTheme.lemon);
      case 'special':
        _rays(canvas, center, s * 0.42);
        _dumpling(canvas, center, s * 0.42, DumplingTheme.lemon);
      case 'special5':
        _plate(canvas, center.translate(0, s * 0.18), s * 0.4);
        _dumpling(canvas, center.translate(0, s * 0.02), s * 0.4,
            DumplingTheme.mint);
      case 'steam_champ':
        _cloud(canvas, center.translate(0, -s * 0.2), s * 0.3);
        _dumpling(canvas, center.translate(0, s * 0.08), s * 0.42,
            DumplingTheme.sky);
      case 'pan_master':
        _pan(canvas, center.translate(0, s * 0.1), s * 0.42);
        _dumpling(canvas, center.translate(0, -s * 0.02), s * 0.36,
            DumplingTheme.lemon);
      case 'spice_legend':
        _flame(canvas, center.translate(-s * 0.2, -s * 0.1), s * 0.2);
        _flame(canvas, center.translate(s * 0.2, -s * 0.1), s * 0.2);
        _flame(canvas, center.translate(0, -s * 0.2), s * 0.26);
        _dumpling(canvas, center.translate(0, s * 0.08), s * 0.42,
            DumplingTheme.peach);
      case 'golden':
        _dumpling(canvas, center.translate(0, s * 0.06), s * 0.44,
            DumplingTheme.lemon);
        _crown(canvas, center.translate(0, -s * 0.2), s * 0.3);
      default:
        _dumpling(canvas, center, s * 0.5, DumplingTheme.lemon);
    }
  }

  void _dumpling(Canvas canvas, Offset center, double size, Color color) {
    paintDumpling(
      canvas,
      Rect.fromCenter(center: center, width: size, height: size),
      color,
    );
  }

  void _chefHat(Canvas canvas, Offset center, double w) {
    final paint = Paint()..color = Colors.white;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..color = DumplingTheme.ink.withValues(alpha: 0.3);
    final band = Rect.fromCenter(
        center: center.translate(0, w * 0.18),
        width: w * 0.7,
        height: w * 0.22);
    final path = Path()
      ..addOval(Rect.fromCircle(
          center: center.translate(-w * 0.22, -w * 0.05), radius: w * 0.2))
      ..addOval(Rect.fromCircle(
          center: center.translate(0, -w * 0.14), radius: w * 0.22))
      ..addOval(Rect.fromCircle(
          center: center.translate(w * 0.22, -w * 0.05), radius: w * 0.2))
      ..addRRect(
          RRect.fromRectAndRadius(band, Radius.circular(w * 0.06)));
    canvas.drawPath(path, paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(band, Radius.circular(w * 0.06)), outline);
  }

  void _crown(Canvas canvas, Offset center, double w) {
    final path = Path()
      ..moveTo(center.dx - w * 0.5, center.dy + w * 0.25)
      ..lineTo(center.dx - w * 0.5, center.dy - w * 0.15)
      ..lineTo(center.dx - w * 0.25, center.dy + w * 0.05)
      ..lineTo(center.dx, center.dy - w * 0.3)
      ..lineTo(center.dx + w * 0.25, center.dy + w * 0.05)
      ..lineTo(center.dx + w * 0.5, center.dy - w * 0.15)
      ..lineTo(center.dx + w * 0.5, center.dy + w * 0.25)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE8A93C));
    canvas.drawCircle(center.translate(0, w * 0.02), w * 0.07,
        Paint()..color = DumplingTheme.pink);
  }

  void _star(Canvas canvas, Offset center, double r, {Color? color}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final radius = i.isEven ? r : r * 0.45;
      final p = center + Offset(cos(angle), sin(angle)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path..close(), Paint()..color = color ?? DumplingTheme.star);
  }

  void _heart(Canvas canvas, Offset center, double r) {
    final path = Path()
      ..moveTo(center.dx, center.dy + r)
      ..cubicTo(center.dx - r * 1.5, center.dy - r * 0.3,
          center.dx - r * 0.6, center.dy - r * 1.3, center.dx,
          center.dy - r * 0.4)
      ..cubicTo(center.dx + r * 0.6, center.dy - r * 1.3,
          center.dx + r * 1.5, center.dy - r * 0.3, center.dx,
          center.dy + r)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF06A7E));
  }

  void _flame(Canvas canvas, Offset center, double h) {
    final path = Path()
      ..moveTo(center.dx, center.dy - h * 0.6)
      ..quadraticBezierTo(center.dx + h * 0.45, center.dy - h * 0.1,
          center.dx + h * 0.3, center.dy + h * 0.3)
      ..quadraticBezierTo(
          center.dx, center.dy + h * 0.55, center.dx - h * 0.3,
          center.dy + h * 0.3)
      ..quadraticBezierTo(center.dx - h * 0.45, center.dy - h * 0.1,
          center.dx, center.dy - h * 0.6)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF2913D));
    canvas.drawCircle(center.translate(0, h * 0.15), h * 0.22,
        Paint()..color = DumplingTheme.lemon);
  }

  void _cloud(Canvas canvas, Offset center, double w) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(center.translate(-w * 0.35, 0), w * 0.28, paint);
    canvas.drawCircle(center.translate(0, -w * 0.12), w * 0.36, paint);
    canvas.drawCircle(center.translate(w * 0.35, 0), w * 0.28, paint);
  }

  void _pan(Canvas canvas, Offset center, double w) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 1.3, height: w * 0.5),
      Paint()..color = const Color(0xFF8B8B94),
    );
    canvas.drawLine(
      center.translate(w * 0.6, 0),
      center.translate(w * 1.0, -w * 0.12),
      Paint()
        ..strokeWidth = w * 0.12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6E6E76),
    );
  }

  void _plate(Canvas canvas, Offset center, double w) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 1.4, height: w * 0.45),
      Paint()..color = Colors.white,
    );
  }

  void _chopsticks(Canvas canvas, Offset center, double s) {
    final paint = Paint()
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round
      ..color = DumplingTheme.bambooDark;
    canvas.drawLine(center.translate(-s * 0.3, -s * 0.28),
        center.translate(s * 0.24, s * 0.3), paint);
    canvas.drawLine(center.translate(s * 0.3, -s * 0.28),
        center.translate(-s * 0.24, s * 0.3), paint);
  }

  void _rays(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..color = DumplingTheme.star.withValues(alpha: 0.8);
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(
          center + dir * r * 0.72, center + dir * r * 0.95, paint);
    }
  }

  @override
  bool shouldRepaint(_StickerPainter old) => old.badgeId != badgeId;
}
