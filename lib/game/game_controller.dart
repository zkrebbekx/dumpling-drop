import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'board.dart';
import 'levels.dart';
import 'piece.dart';

enum GamePhase { ready, playing, clearing, paused, won, lost }

/// Things that happen during play. The UI listens to play sounds and
/// spawn particles.
enum GameEvent {
  move,
  rotate,
  softDrop,
  hardDrop,
  lock,
  clear,
  feast, // four lines at once
  combo,
  win,
  lose,
}

typedef GameEventListener = void Function(GameEvent event, {List<int>? rows});

/// Runs one game of Dumpling Drop for one level.
///
/// Pure game state lives here; no widgets, no audio. The screen listens
/// via [ChangeNotifier] for state and via [onEvent] for moments.
class GameController extends ChangeNotifier {
  final LevelConfig level;
  final Random _random;
  final List<GameEventListener> _eventListeners = [];

  void addEventListener(GameEventListener listener) =>
      _eventListeners.add(listener);

  void removeEventListener(GameEventListener listener) =>
      _eventListeners.remove(listener);

  void _emit(GameEvent event, {List<int>? rows}) {
    for (final listener in List.of(_eventListeners)) {
      listener(event, rows: rows);
    }
  }

  late Board board;
  GamePhase phase = GamePhase.ready;

  Piece? current;
  int pieceRow = 0;
  int pieceCol = 0;
  int rotation = 0;
  late Piece next;

  int score = 0;
  int linesCleared = 0;
  int combo = 0;
  int maxCombo = 0;
  int feasts = 0;
  int piecesPlaced = 0;

  /// Rows currently playing their clear animation.
  List<int> clearingRows = const [];

  Timer? _gravityTimer;
  Timer? _lockTimer;
  Timer? _clearTimer;
  int _lockResets = 0;
  final List<PieceKind> _bag = [];

  static const _lockDelay = Duration(milliseconds: 450);
  static const _clearDelay = Duration(milliseconds: 420);
  static const _maxLockResets = 4;

  GameController({required this.level, int? seed})
      : _random = Random(seed) {
    board = Board(rows: level.rows, cols: level.cols);
    next = Piece(_draw());
  }

  bool get isRunning => phase == GamePhase.playing;

  /// The row where the current piece would land on a hard drop.
  int get ghostRow {
    final piece = current;
    if (piece == null) return pieceRow;
    var row = pieceRow;
    while (board.canPlace(piece, row + 1, pieceCol, rotation)) {
      row++;
    }
    return row;
  }

  double get goalProgress =>
      (linesCleared / level.goalLines).clamp(0.0, 1.0);

  int starsForScore() {
    if (score >= level.threeStarScore) return 3;
    if (score >= level.twoStarScore) return 2;
    return 1;
  }

  void start() {
    if (phase != GamePhase.ready) return;
    phase = GamePhase.playing;
    _spawn();
    _startGravity();
    notifyListeners();
  }

  void pause() {
    if (phase != GamePhase.playing) return;
    phase = GamePhase.paused;
    _stopTimers();
    notifyListeners();
  }

  void resume() {
    if (phase != GamePhase.paused) return;
    phase = GamePhase.playing;
    _startGravity();
    notifyListeners();
  }

  void moveLeft() => _move(-1);
  void moveRight() => _move(1);

  void _move(int dc) {
    final piece = current;
    if (!isRunning || piece == null) return;
    if (board.canPlace(piece, pieceRow, pieceCol + dc, rotation)) {
      pieceCol += dc;
      _resetLockIfGrounded();
      _emit(GameEvent.move);
      notifyListeners();
    }
  }

  void rotate() {
    final piece = current;
    if (!isRunning || piece == null) return;
    final newRotation = (rotation + 1) % Piece.rotationCount;
    // Simple wall kicks: try in place, then one or two columns to the
    // side, then one row up. Enough forgiveness for small hands.
    const kicks = [(0, 0), (0, -1), (0, 1), (0, -2), (0, 2), (-1, 0)];
    for (final (dr, dc) in kicks) {
      if (board.canPlace(piece, pieceRow + dr, pieceCol + dc, newRotation)) {
        pieceRow += dr;
        pieceCol += dc;
        rotation = newRotation;
        _resetLockIfGrounded();
        _emit(GameEvent.rotate);
        notifyListeners();
        return;
      }
    }
  }

  void softDrop() {
    final piece = current;
    if (!isRunning || piece == null) return;
    if (board.canPlace(piece, pieceRow + 1, pieceCol, rotation)) {
      pieceRow++;
      score += 1;
      _emit(GameEvent.softDrop);
      notifyListeners();
    }
  }

  void hardDrop() {
    final piece = current;
    if (!isRunning || piece == null) return;
    final target = ghostRow;
    score += (target - pieceRow) * 2;
    pieceRow = target;
    _emit(GameEvent.hardDrop);
    _lockPiece();
  }

  void _startGravity() {
    _gravityTimer?.cancel();
    _gravityTimer = Timer.periodic(level.gravity, (_) => _tick());
  }

  void _stopTimers() {
    _gravityTimer?.cancel();
    _lockTimer?.cancel();
    _clearTimer?.cancel();
  }

  void _tick() {
    final piece = current;
    if (!isRunning || piece == null) return;
    if (board.canPlace(piece, pieceRow + 1, pieceCol, rotation)) {
      pieceRow++;
      _lockTimer?.cancel();
      notifyListeners();
    } else {
      _armLockTimer();
    }
  }

  bool get _grounded {
    final piece = current;
    if (piece == null) return false;
    return !board.canPlace(piece, pieceRow + 1, pieceCol, rotation);
  }

  void _armLockTimer() {
    if (_lockTimer?.isActive ?? false) return;
    _lockTimer = Timer(_lockDelay, () {
      if (isRunning && _grounded) _lockPiece();
    });
  }

  void _resetLockIfGrounded() {
    if (!_grounded) {
      _lockTimer?.cancel();
      _lockResets = 0;
      return;
    }
    if (_lockResets < _maxLockResets) {
      _lockResets++;
      _lockTimer?.cancel();
      _armLockTimer();
    }
  }

  void _lockPiece() {
    final piece = current;
    if (piece == null) return;
    _lockTimer?.cancel();
    _lockResets = 0;
    final inside = board.lock(piece, pieceRow, pieceCol, rotation);
    piecesPlaced++;
    current = null;
    _emit(GameEvent.lock);

    if (!inside) {
      _finish(GamePhase.lost);
      return;
    }

    final full = board.fullRows();
    if (full.isEmpty) {
      combo = 0;
      _spawn();
      notifyListeners();
      return;
    }

    // Score the clear.
    const lineScores = [0, 100, 300, 600, 1000];
    score += lineScores[min(full.length, 4)];
    if (combo > 0) {
      score += combo * 50;
      _emit(GameEvent.combo);
    }
    combo++;
    maxCombo = max(maxCombo, combo);
    linesCleared += full.length;
    if (full.length >= 4) {
      feasts++;
      _emit(GameEvent.feast, rows: full);
    } else {
      _emit(GameEvent.clear, rows: full);
    }

    // Pause for the pop animation, then collapse and continue.
    clearingRows = full;
    phase = GamePhase.clearing;
    _gravityTimer?.cancel();
    notifyListeners();
    _clearTimer = Timer(_clearDelay, _finishClear);
  }

  void _finishClear() {
    board.removeRows(clearingRows);
    clearingRows = const [];
    if (linesCleared >= level.goalLines) {
      _finish(GamePhase.won);
      return;
    }
    phase = GamePhase.playing;
    _spawn();
    _startGravity();
    notifyListeners();
  }

  void _spawn() {
    final piece = next;
    next = Piece(_draw());
    current = piece;
    rotation = 0;
    pieceCol = (level.cols - piece.width(0)) ~/ 2 - 1;
    // Nudge inside if the centering guess is off for narrow boards.
    if (pieceCol < -1) pieceCol = -1;
    pieceRow = -2;
    if (!board.canPlace(piece, pieceRow, pieceCol, rotation)) {
      _finish(GamePhase.lost);
    }
  }

  void _finish(GamePhase end) {
    _stopTimers();
    phase = end;
    notifyListeners();
    _emit(end == GamePhase.won ? GameEvent.win : GameEvent.lose);
  }

  /// Advances gravity once. Test hook.
  @visibleForTesting
  void debugTick() => _tick();

  /// Completes a pending clear at once. Test hook.
  @visibleForTesting
  void debugFinishClear() {
    _clearTimer?.cancel();
    if (phase == GamePhase.clearing) _finishClear();
  }

  PieceKind _draw() {
    if (_bag.isEmpty) {
      _bag.addAll(level.pieceKinds);
      _bag.shuffle(_random);
    }
    return _bag.removeLast();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
