// Renders the launcher icon from the same painter the app uses.
//
// Not part of the normal suite. Run it on purpose:
//   flutter test test/tools/gen_icon_test.dart --dart-define=genIcon=true
// It writes build/icon-1024.png. The repo tool script resizes that
// into the Android mipmap folders.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dumpling_drop/theme.dart';
import 'package:dumpling_drop/widgets/dumpling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('genIcon');

void main() {
  testWidgets('render launcher icon', (tester) async {
    if (!_enabled) {
      markTestSkipped('Pass --dart-define=genIcon=true to render the icon.');
      return;
    }
    await tester.runAsync(() async {
      const size = 1024.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const rect = Rect.fromLTWH(0, 0, size, size);

      // Soft cream background with a warm glow.
      canvas.drawRect(rect, Paint()..color = DumplingTheme.cream);
      canvas.drawCircle(
        rect.center,
        size * 0.52,
        Paint()
          ..shader = RadialGradient(colors: [
            DumplingTheme.peach.withValues(alpha: 0.55),
            DumplingTheme.peach.withValues(alpha: 0),
          ]).createShader(rect),
      );

      // Sparkle stars around the mascot.
      final starPaint = Paint()..color = DumplingTheme.star;
      for (final (cx, cy, r) in [
        (0.18, 0.22, 0.045),
        (0.82, 0.20, 0.035),
        (0.85, 0.62, 0.045),
        (0.16, 0.68, 0.033),
      ]) {
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final angle = -pi / 2 + i * pi / 5;
          final radius = (i.isEven ? r : r * 0.45) * size;
          final p = Offset(cx * size + cos(angle) * radius,
              cy * size + sin(angle) * radius);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), starPaint);
      }

      // The hero dumpling, slightly squished and happy.
      paintDumpling(
        canvas,
        Rect.fromCenter(
            center: rect.center.translate(0, size * 0.04),
            width: size * 0.62,
            height: size * 0.62),
        DumplingTheme.lemon,
        squish: 0.18,
      );

      final image =
          await recorder.endRecording().toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/icon-1024.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
      expect(file.existsSync(), isTrue);
    });
  });
}
