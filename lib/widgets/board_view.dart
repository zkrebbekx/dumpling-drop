import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../theme.dart';
import 'dumpling.dart';

class _Particle {
  Offset pos;
  Offset vel;
  Color color;
  double size;
  double life; // seconds remaining
  final double fullLife;
  final bool sparkle;

  _Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    required this.life,
    this.sparkle = false,
  }) : fullLife = life;
}

/// Draws the play field: the steamer well, locked dumplings, the ghost,
/// the falling piece, clear animations, and pop particles.
class BoardView extends StatefulWidget {
  final GameController controller;

  const BoardView({super.key, required this.controller});

  @override
  State<BoardView> createState() => BoardViewState();
}

class BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final List<_Particle> _particles = [];
  final _random = Random();

  Duration _lastTick = Duration.zero;
  double _time = 0;

  // Animation anchors, in seconds on the _time clock.
  double _clearStart = -10;
  List<int> _clearRows = const [];
  double _lockPulse = -10;
  double _shakeStart = -10;

  Size _cellSizeFor(Size size) {
    final cols = widget.controller.level.cols;
    final rows = widget.controller.level.rows;
    final cell = min(size.width / cols, size.height / rows);
    return Size(cell, cell);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addEventListener(_onGameEvent);
    _ticker = AnimationController(
        vsync: this, duration: const Duration(days: 1))
      ..addListener(_step)
      ..forward();
  }

  @override
  void dispose() {
    widget.controller.removeEventListener(_onGameEvent);
    _ticker.dispose();
    super.dispose();
  }

  void _step() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt =
        (now - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = now;
    _time += dt;
    if (dt <= 0) return;

    for (final p in _particles) {
      p.pos += p.vel * dt;
      p.vel += const Offset(0, 900) * dt; // gravity
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
    setState(() {});
  }

  void _onGameEvent(GameEvent event, {List<int>? rows}) {
    if (!mounted) return;
    switch (event) {
      case GameEvent.lock:
        _lockPulse = _time;
      case GameEvent.clear:
        _clearStart = _time;
        _clearRows = rows ?? const [];
        _spawnRowParticles(rows ?? const [], sparkles: 4);
      case GameEvent.feast:
        _clearStart = _time;
        _clearRows = rows ?? const [];
        _shakeStart = _time;
        _spawnRowParticles(rows ?? const [], sparkles: 14);
      case GameEvent.hardDrop:
        _lockPulse = _time;
      default:
        break;
    }
  }

  void _spawnRowParticles(List<int> rows, {int sparkles = 0}) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cell = _cellSizeFor(size).width;
    final cols = widget.controller.level.cols;
    final boardWidth = cell * cols;
    final left = (size.width - boardWidth) / 2;

    for (final row in rows) {
      for (var c = 0; c < cols; c++) {
        final kind = widget.controller.board.at(row, c);
        final color = kind == null
            ? DumplingTheme.peach
            : DumplingTheme.fillings[kind.index];
        final origin = Offset(
          left + (c + 0.5) * cell,
          (row + 0.5) * cell,
        );
        for (var i = 0; i < 3; i++) {
          _particles.add(_Particle(
            pos: origin,
            vel: Offset(
              (_random.nextDouble() - 0.5) * 320,
              -_random.nextDouble() * 380 - 60,
            ),
            color: shade(color, _random.nextDouble() * 0.15),
            size: cell * (0.10 + _random.nextDouble() * 0.14),
            life: 0.5 + _random.nextDouble() * 0.4,
          ));
        }
      }
      for (var i = 0; i < sparkles; i++) {
        _particles.add(_Particle(
          pos: Offset(
            left + _random.nextDouble() * boardWidth,
            (row + 0.5) * cell,
          ),
          vel: Offset(
            (_random.nextDouble() - 0.5) * 200,
            -_random.nextDouble() * 500 - 100,
          ),
          color: DumplingTheme.star,
          size: cell * 0.12,
          life: 0.6 + _random.nextDouble() * 0.5,
          sparkle: true,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoardPainter(
        controller: widget.controller,
        particles: _particles,
        time: _time,
        clearStart: _clearStart,
        clearRows: _clearRows,
        lockPulse: _lockPulse,
        shakeStart: _shakeStart,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final GameController controller;
  final List<_Particle> particles;
  final double time;
  final double clearStart;
  final List<int> clearRows;
  final double lockPulse;
  final double shakeStart;

  _BoardPainter({
    required this.controller,
    required this.particles,
    required this.time,
    required this.clearStart,
    required this.clearRows,
    required this.lockPulse,
    required this.shakeStart,
  });

  static const _clearSeconds = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = controller.level.cols;
    final rows = controller.level.rows;
    final cell = min(size.width / cols, size.height / rows);
    final boardWidth = cell * cols;
    final boardHeight = cell * rows;
    final left = (size.width - boardWidth) / 2;
    final boardRect = Rect.fromLTWH(left, 0, boardWidth, boardHeight);

    canvas.save();

    // Feast shake: a quick decaying wiggle.
    final shakeAge = time - shakeStart;
    if (shakeAge < 0.4) {
      final decay = 1 - shakeAge / 0.4;
      canvas.translate(
        sin(shakeAge * 55) * 5 * decay,
        cos(shakeAge * 47) * 4 * decay,
      );
    }

    // The steamer well.
    final wellRadius = Radius.circular(cell * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(cell * 0.12), wellRadius),
      Paint()..color = DumplingTheme.bamboo,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, wellRadius),
      Paint()..color = DumplingTheme.boardWell,
    );

    // Faint grid dots so kids can judge columns.
    final dotPaint = Paint()
      ..color = DumplingTheme.bamboo.withValues(alpha: 0.25);
    for (var r = 1; r < rows; r++) {
      for (var c = 1; c < cols; c++) {
        canvas.drawCircle(
          Offset(left + c * cell, r * cell),
          cell * 0.035,
          dotPaint,
        );
      }
    }

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(boardRect, wellRadius));

    // Jelly pulse when a piece locks: the stack squashes a touch.
    final pulseAge = time - lockPulse;
    if (pulseAge < 0.22) {
      final k = sin(pulseAge / 0.22 * pi) * 0.02;
      canvas.translate(boardRect.center.dx, boardRect.bottom);
      canvas.scale(1 + k, 1 - k);
      canvas.translate(-boardRect.center.dx, -boardRect.bottom);
    }

    Rect cellRect(int row, int col) => Rect.fromLTWH(
          left + col * cell + cell * 0.03,
          row * cell + cell * 0.03,
          cell * 0.94,
          cell * 0.94,
        );

    // Locked dumplings.
    final clearing = clearRows.toSet();
    final clearAge = time - clearStart;
    final clearProgress =
        controller.clearingRows.isEmpty ? 1.0 : (clearAge / _clearSeconds);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final kind = controller.board.at(r, c);
        if (kind == null) continue;
        final color = DumplingTheme.fillings[kind.index];
        final rect = cellRect(r, c);
        if (clearing.contains(r) && controller.clearingRows.isNotEmpty) {
          // Pop! Grow a little, then shrink away, staggered per column.
          final local =
              ((clearProgress - c * 0.02).clamp(0.0, 1.0)).toDouble();
          final scale = local < 0.3
              ? 1 + local * 0.6
              : max(0.0, 1.18 * (1 - (local - 0.3) / 0.7));
          if (scale <= 0.01) continue;
          final scaled = Rect.fromCenter(
            center: rect.center,
            width: rect.width * scale,
            height: rect.height * scale,
          );
          paintDumpling(canvas, scaled, color,
              eyeOpen: 0, alpha: (1.2 - local).clamp(0.0, 1.0).toDouble());
        } else {
          // Idle dumplings blink now and then.
          final phase = (r * 13 + c * 7) % 40 / 10.0;
          final blinkT = (time + phase) % 4.0;
          paintDumpling(canvas, rect, color,
              eyeOpen: blinkT < 0.12 ? 0 : 1);
        }
      }
    }

    // Ghost: where the piece would land.
    final piece = controller.current;
    if (piece != null && controller.isRunning) {
      final ghostRow = controller.ghostRow;
      if (ghostRow != controller.pieceRow) {
        final color = piece.color(DumplingTheme.fillings);
        for (final pc in piece.cells(controller.rotation)) {
          final r = ghostRow + pc.row;
          final c = controller.pieceCol + pc.col;
          if (r < 0) continue;
          paintDumpling(canvas, cellRect(r, c), color,
              face: false, alpha: 0.22);
        }
      }

      // The falling piece, with a gentle wobble and a squish when it
      // rests on the stack.
      final grounded = ghostRow == controller.pieceRow;
      final wobble = sin(time * 6) * 0.03;
      final squish = grounded ? 0.35 : wobble.abs();
      for (final pc in piece.cells(controller.rotation)) {
        final r = controller.pieceRow + pc.row;
        final c = controller.pieceCol + pc.col;
        if (r < 0) continue;
        paintDumpling(
          canvas,
          cellRect(r, c),
          piece.color(DumplingTheme.fillings),
          squish: squish,
        );
      }
    }

    canvas.restore();

    // Particles fly above everything, outside the clip.
    for (final p in particles) {
      final fade = (p.life / p.fullLife).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      if (p.sparkle) {
        _paintStar(canvas, p.pos, p.size * (0.7 + fade * 0.5), paint);
      } else {
        canvas.drawCircle(p.pos, p.size * (0.6 + fade * 0.4), paint);
      }
    }

    canvas.restore();
  }

  void _paintStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final radius = i.isEven ? r : r * 0.45;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
