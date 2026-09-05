import 'package:dumpling_drop/game/game_controller.dart';
import 'package:dumpling_drop/game/levels.dart';
import 'package:dumpling_drop/game/piece.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

LevelConfig testLevel({
  int rows = 8,
  int cols = 4,
  int goalLines = 2,
  List<PieceKind> kinds = const [PieceKind.bao],
}) {
  return LevelConfig(
    number: 1,
    name: 'Test',
    difficulty: Difficulty.easy,
    rows: rows,
    cols: cols,
    gravity: const Duration(milliseconds: 100),
    goalLines: goalLines,
    pieceKinds: kinds,
    twoStarScore: 200,
    threeStarScore: 400,
  );
}

void main() {
  test('start spawns a piece and gravity pulls it down', () {
    fakeAsync((async) {
      final game = GameController(level: testLevel(), seed: 1);
      game.start();
      expect(game.phase, GamePhase.playing);
      expect(game.current, isNotNull);
      final startRow = game.pieceRow;
      async.elapse(const Duration(milliseconds: 350));
      expect(game.pieceRow, greaterThan(startRow));
      game.dispose();
    });
  });

  test('hard drop locks the piece at the ghost row', () {
    fakeAsync((async) {
      final game = GameController(level: testLevel(), seed: 1);
      game.start();
      final ghost = game.ghostRow;
      expect(ghost, greaterThan(game.pieceRow));
      game.hardDrop();
      // The bao locks in its ghost position; a new piece spawns.
      expect(game.board.highestOccupiedRow(), lessThan(game.level.rows));
      expect(game.piecesPlaced, 1);
      expect(game.current, isNotNull);
      game.dispose();
    });
  });

  test('two bao pieces on a 4-wide board clear two lines and win', () {
    fakeAsync((async) {
      final game = GameController(level: testLevel(), seed: 1);
      final events = <GameEvent>[];
      game.addEventListener((e, {rows}) => events.add(e));
      game.start();

      // First bao: push to the left wall and drop.
      while (game.board.canPlace(
          game.current!, game.pieceRow, game.pieceCol - 1, game.rotation)) {
        game.moveLeft();
      }
      game.hardDrop();

      // Second bao: push to the right wall and drop. Board is 4 wide,
      // each bao is 2 wide, so the bottom two rows fill completely.
      while (game.board.canPlace(
          game.current!, game.pieceRow, game.pieceCol + 1, game.rotation)) {
        game.moveRight();
      }
      game.hardDrop();

      expect(game.phase, GamePhase.clearing);
      expect(game.clearingRows.length, 2);
      async.elapse(const Duration(milliseconds: 500));

      expect(game.linesCleared, 2);
      expect(game.phase, GamePhase.won);
      expect(events, contains(GameEvent.clear));
      expect(events, contains(GameEvent.win));
      // Double clear scores 300 plus hard-drop points.
      expect(game.score, greaterThanOrEqualTo(300));
      game.dispose();
    });
  });

  test('pause stops gravity and resume continues', () {
    fakeAsync((async) {
      final game = GameController(level: testLevel(), seed: 1);
      game.start();
      game.pause();
      final row = game.pieceRow;
      async.elapse(const Duration(seconds: 2));
      expect(game.pieceRow, row);
      game.resume();
      async.elapse(const Duration(milliseconds: 250));
      expect(game.pieceRow, greaterThan(row));
      game.dispose();
    });
  });

  test('a full board ends the game with lost', () {
    fakeAsync((async) {
      final game = GameController(level: testLevel(goalLines: 99), seed: 1);
      game.start();
      // Stack bao pieces in the same columns until the well overflows.
      var safety = 0;
      while (game.phase == GamePhase.playing && safety < 30) {
        game.hardDrop();
        safety++;
      }
      expect(game.phase, GamePhase.lost);
      game.dispose();
    });
  });

  test('rotation kicks away from the wall', () {
    fakeAsync((async) {
      final game = GameController(
        level: testLevel(cols: 6, kinds: [PieceKind.po]),
        seed: 1,
      );
      game.start();
      game.rotate(); // vertical po
      // Slam into the left wall.
      for (var i = 0; i < 6; i++) {
        game.moveLeft();
      }
      final before = game.rotation;
      game.rotate(); // must kick, not stay stuck
      expect(game.rotation, isNot(before));
      game.dispose();
    });
  });

  test('soft drop adds points and moves down', () {
    fakeAsync((async) {
      final game = GameController(level: testLevel(), seed: 1);
      game.start();
      final row = game.pieceRow;
      final score = game.score;
      game.softDrop();
      expect(game.pieceRow, row + 1);
      expect(game.score, score + 1);
      game.dispose();
    });
  });

  test('stars follow the score thresholds', () {
    final game = GameController(level: testLevel(), seed: 1);
    expect(game.starsForScore(), 1);
    game.score = 250;
    expect(game.starsForScore(), 2);
    game.score = 500;
    expect(game.starsForScore(), 3);
    game.dispose();
  });

  test('bag deals every allowed kind before repeating', () {
    fakeAsync((async) {
      final level = testLevel(
        rows: 30,
        cols: 12,
        goalLines: 99,
        kinds: PieceKind.values,
      );
      final game = GameController(level: level, seed: 42);
      game.start();
      final seen = <PieceKind>{game.current!.kind, game.next.kind};
      // Draw through one full bag: 7 kinds total.
      for (var i = 0; i < 5 && game.phase == GamePhase.playing; i++) {
        game.hardDrop();
        if (game.phase == GamePhase.clearing) {
          async.elapse(const Duration(milliseconds: 500));
        }
        seen.add(game.current!.kind);
      }
      seen.add(game.next.kind);
      expect(seen, PieceKind.values.toSet());
      game.dispose();
    });
  });
}
