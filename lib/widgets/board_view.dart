import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/piece.dart';
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

  /// Steam drifts up slowly, ignores gravity, and grows as it fades.
  final bool steam;

  _Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    required this.life,
    this.sparkle = false,
    this.steam = false,
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

class _FloatText {
  final String text;
  final Offset origin;
  double age = 0;

  _FloatText(this.text, this.origin);
}

class BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final List<_Particle> _particles = [];
  final List<_FloatText> _floaters = [];
  final _random = Random();

  Duration _lastTick = Duration.zero;
  double _time = 0;

  // Animation anchors, in seconds on the _time clock.
  double _clearStart = -10;
  List<int> _clearRows = const [];
  double _lockPulse = -10;
  double _shakeStart = -10;
  double _leanTime = -10;
  int _leanDir = 0;
  double _lastSteam = 0;
  bool _reduceMotion = false;

  // Snapshot of the falling piece, kept so the lock event (which
  // fires after the controller clears `current`) still knows who
  // landed where.
  Piece? _fallingPiece;
  int _fallingRow = 0;
  int _fallingCol = 0;
  int _fallingRot = 0;

  static const _rainbow = [
    Color(0xFFF06A6A),
    Color(0xFFF7A24B),
    Color(0xFFF7C948),
    Color(0xFF7BC47F),
    Color(0xFF6FB7E8),
    Color(0xFFB48CE8),
  ];

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
        vsync: this, duration: const Duration(hours: 1))
      ..addListener(_step)
      ..repeat();
  }

  @override
  void didUpdateWidget(BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A restart swaps in a fresh controller; follow it or every
    // pop/particle/shake goes silent for the rest of the session.
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeEventListener(_onGameEvent);
      widget.controller.addEventListener(_onGameEvent);
      _particles.clear();
      _clearRows = const [];
    }
  }

  @override
  void dispose() {
    widget.controller.removeEventListener(_onGameEvent);
    _ticker.dispose();
    super.dispose();
  }

  void _step() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    var dt =
        (now - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = now;
    // repeat() wraps the elapsed clock once per period.
    if (dt < 0) dt = 0;
    _time += dt;
    if (dt <= 0) return;

    for (final p in _particles) {
      p.pos += p.vel * dt;
      if (!p.steam) p.vel += const Offset(0, 900) * dt; // gravity
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);

    final current = widget.controller.current;
    if (current != null) {
      _fallingPiece = current;
      _fallingRow = widget.controller.pieceRow;
      _fallingCol = widget.controller.pieceCol;
      _fallingRot = widget.controller.rotation;
    }

    // Cozy ambience: a steam puff rises from the stack now and then.
    if (!_reduceMotion &&
        widget.controller.phase == GamePhase.playing &&
        _time - _lastSteam > 1.6) {
      _lastSteam = _time;
      _spawnSteamPuff();
    }
    for (final f in _floaters) {
      f.age += dt;
    }
    _floaters.removeWhere((f) => f.age > 1.0);

    // Repaint only while something moves. Idle overlays (ready,
    // paused, results) must not burn a full-board paint per frame.
    final phase = widget.controller.phase;
    final animating = phase == GamePhase.playing ||
        phase == GamePhase.clearing ||
        _particles.isNotEmpty ||
        _floaters.isNotEmpty ||
        (_time - _lockPulse) < 0.3 ||
        (_time - _shakeStart) < 0.5;
    if (animating) setState(() {});
  }

  void _onGameEvent(GameEvent event, {List<int>? rows, int? points}) {
    if (!mounted) return;
    switch (event) {
      case GameEvent.lock:
        _lockPulse = _time;
        _spawnCharacterSparkles();
      case GameEvent.move:
        // Which way did the piece go? Peek at the drag direction via
        // a tiny lean impulse; direction comes from column deltas.
        _leanTime = _time;
        _leanDir = widget.controller.pieceCol >= _lastCol ? 1 : -1;
        _lastCol = widget.controller.pieceCol;
      case GameEvent.clear:
        _clearStart = _time;
        _clearRows = rows ?? const [];
        _spawnRowParticles(rows ?? const [], sparkles: 4);
        _spawnFloater(rows, points);
      case GameEvent.feast:
        _clearStart = _time;
        _clearRows = rows ?? const [];
        _shakeStart = _time;
        _spawnRowParticles(rows ?? const [], sparkles: 14);
        _spawnFloater(rows, points);
      case GameEvent.hardDrop:
        _lockPulse = _time;
        // A hard drop teleports the piece; the controller still holds
        // the final position while this event fires.
        final current = widget.controller.current;
        if (current != null) {
          _fallingPiece = current;
          _fallingRow = widget.controller.pieceRow;
          _fallingCol = widget.controller.pieceCol;
          _fallingRot = widget.controller.rotation;
        }
        _spawnImpactDust();
      default:
        break;
    }
  }

  int _lastCol = 0;

  /// A soft white puff drifting up from the top of a random occupied
  /// column. Makes the basket feel freshly steamed.
  void _spawnSteamPuff() {
    final controller = widget.controller;
    final board = controller.board;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final occupied = <(int, int)>[];
    for (var c = 0; c < controller.level.cols; c++) {
      for (var r = 0; r < controller.level.rows; r++) {
        if (board.at(r, c) != null) {
          occupied.add((r, c));
          break;
        }
      }
    }
    if (occupied.isEmpty) return;
    final (row, col) = occupied[_random.nextInt(occupied.length)];
    final size = box.size;
    final cell = _cellSizeFor(size).width;
    final left = (size.width - cell * controller.level.cols) / 2;
    _particles.add(_Particle(
      pos: Offset(
          left + (col + 0.3 + _random.nextDouble() * 0.4) * cell,
          row * cell),
      vel: Offset((_random.nextDouble() - 0.5) * 12, -26 - _random.nextDouble() * 14),
      color: Colors.white,
      size: cell * (0.16 + _random.nextDouble() * 0.1),
      life: 1.6,
      steam: true,
    ));
  }

  /// Mei leaves a rainbow where she lands; Ube dusts the spot with
  /// glitter. The other dumplings land like normal dumplings.
  void _spawnCharacterSparkles() {
    final piece = _fallingPiece;
    if (piece == null || _reduceMotion) return;
    final kind = piece.kind;
    if (kind != PieceKind.mei && kind != PieceKind.ube) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cell = _cellSizeFor(size).width;
    final left = (size.width - cell * widget.controller.level.cols) / 2;

    final cells = piece.cells(_fallingRot);
    for (var i = 0; i < cells.length; i++) {
      final pc = cells[i];
      final origin = Offset(
        left + (_fallingCol + pc.col + 0.5) * cell,
        (_fallingRow + pc.row + 0.3) * cell,
      );
      for (var j = 0; j < 2; j++) {
        final color = kind == PieceKind.mei
            ? _rainbow[(i * 2 + j) % _rainbow.length]
            : (j.isEven
                ? Colors.white
                : const Color(0xFFCCB8F0));
        _particles.add(_Particle(
          pos: origin,
          vel: Offset(
            (_random.nextDouble() - 0.5) * 140,
            -_random.nextDouble() * 160 - 40,
          ),
          color: color,
          size: cell * (0.08 + _random.nextDouble() * 0.06),
          life: 0.45 + _random.nextDouble() * 0.3,
          sparkle: true,
        ));
      }
    }
  }

  /// Dust kicked up where a hard-dropped piece slams down.
  void _spawnImpactDust() {
    final controller = widget.controller;
    final piece = controller.current;
    if (piece == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cell = _cellSizeFor(size).width;
    final left = (size.width - cell * controller.level.cols) / 2;
    // The lowest cell in each column of the piece.
    final bottoms = <int, int>{};
    for (final pc in piece.cells(controller.rotation)) {
      final c = controller.pieceCol + pc.col;
      final r = controller.pieceRow + pc.row;
      bottoms[c] = max(bottoms[c] ?? r, r);
    }
    for (final entry in bottoms.entries) {
      for (final dir in [-1, 1]) {
        _particles.add(_Particle(
          pos: Offset(left + (entry.key + 0.5) * cell,
              (entry.value + 1) * cell),
          vel: Offset(dir * (40 + _random.nextDouble() * 60),
              -20 - _random.nextDouble() * 40),
          color: DumplingTheme.creamDark,
          size: cell * 0.12,
          life: 0.3 + _random.nextDouble() * 0.15,
        ));
      }
    }
  }

  void _spawnFloater(List<int>? rows, int? points) {
    if (points == null || rows == null || rows.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cell = _cellSizeFor(size).width;
    final cols = widget.controller.level.cols;
    final left = (size.width - cell * cols) / 2;
    _floaters.add(_FloatText(
      '+$points',
      Offset(left + cell * cols / 2, rows.first * cell),
    ));
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
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    return CustomPaint(
      painter: _BoardPainter(
        controller: widget.controller,
        particles: _particles,
        floaters: _floaters,
        time: _time,
        clearStart: _clearStart,
        clearRows: _clearRows,
        lockPulse: _lockPulse,
        shakeStart: _shakeStart,
        leanTime: _leanTime,
        leanDir: _leanDir,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final GameController controller;
  final List<_Particle> particles;
  final List<_FloatText> floaters;
  final double time;
  final double clearStart;
  final List<int> clearRows;
  final double lockPulse;
  final double shakeStart;
  final double leanTime;
  final int leanDir;

  _BoardPainter({
    required this.controller,
    required this.particles,
    required this.floaters,
    required this.time,
    required this.clearStart,
    required this.clearRows,
    required this.lockPulse,
    required this.shakeStart,
    required this.leanTime,
    required this.leanDir,
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
              eyeOpen: 0,
              alpha: (1.2 - local).clamp(0.0, 1.0).toDouble(),
              kind: kind);
        } else {
          // Idle dumplings blink now and then.
          final phase = (r * 13 + c * 7) % 40 / 10.0;
          final blinkT = (time + phase) % 4.0;
          paintDumpling(canvas, rect, color,
              eyeOpen: blinkT < 0.12 ? 0 : 1, kind: kind);
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

      // The falling piece: a gentle wobble, a squish when it rests on
      // the stack, a lean while moving, and eyes that watch the drop.
      final grounded = ghostRow == controller.pieceRow;
      final wobble = sin(time * 6) * 0.03;
      final squish = grounded ? 0.35 : wobble.abs();
      final leanAge = time - leanTime;
      final lean = leanAge < 0.18
          ? leanDir * 0.14 * (1 - leanAge / 0.18)
          : 0.0;
      final eyeShift =
          grounded ? Offset.zero : const Offset(0, 0.055);
      for (final pc in piece.cells(controller.rotation)) {
        final r = controller.pieceRow + pc.row;
        final c = controller.pieceCol + pc.col;
        if (r < 0) continue;
        paintDumpling(
          canvas,
          cellRect(r, c),
          piece.color(DumplingTheme.fillings),
          squish: squish,
          lean: lean,
          eyeShift: eyeShift,
          kind: piece.kind,
        );
      }
    }

    canvas.restore();

    // Score floaters drift up and fade.
    for (final f in floaters) {
      final fade = f.age < 0.75 ? 1.0 : (1 - f.age) / 0.25;
      final scale = f.age < 0.15 ? 0.6 + f.age / 0.15 * 0.4 : 1.0;
      final painter = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            fontFamily: 'Baloo',
            fontSize: cell * 0.62 * scale,
            fontVariations: const [FontVariation('wght', 800)],
            color: DumplingTheme.ink
                .withValues(alpha: fade.clamp(0.0, 1.0)),
            shadows: [
              Shadow(
                color: Colors.white
                    .withValues(alpha: 0.9 * fade.clamp(0.0, 1.0)),
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        f.origin -
            Offset(painter.width / 2, f.age * cell * 1.6 + painter.height),
      );
    }

    // Particles fly above everything, outside the clip.
    for (final p in particles) {
      final fade = (p.life / p.fullLife).clamp(0.0, 1.0);
      if (p.steam) {
        // Steam grows and thins as it rises.
        canvas.drawCircle(
          p.pos,
          p.size * (1.8 - fade * 0.8),
          Paint()
            ..color = p.color.withValues(alpha: 0.3 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        continue;
      }
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
