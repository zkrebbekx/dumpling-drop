import 'package:dumpling_drop/game/board.dart';
import 'package:dumpling_drop/game/piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Board', () {
    test('starts empty', () {
      final board = Board(rows: 4, cols: 4);
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          expect(board.at(r, c), isNull);
        }
      }
      expect(board.fullRows(), isEmpty);
      expect(board.highestOccupiedRow(), 4);
    });

    test('canPlace rejects out-of-bounds columns and floor', () {
      final board = Board(rows: 6, cols: 4);
      const piece = Piece(PieceKind.bao); // 2x2 at cols 1..2
      expect(board.canPlace(piece, 0, 0, 0), isTrue);
      expect(board.canPlace(piece, 0, -2, 0), isFalse); // off left
      expect(board.canPlace(piece, 0, 2, 0), isFalse); // off right
      expect(board.canPlace(piece, 5, 0, 0), isFalse); // through floor
      expect(board.canPlace(piece, 4, 0, 0), isTrue); // rests on floor
    });

    test('canPlace allows rows above the top', () {
      final board = Board(rows: 6, cols: 4);
      const piece = Piece(PieceKind.bao);
      expect(board.canPlace(piece, -2, 0, 0), isTrue);
    });

    test('lock fills cells and detects overflow', () {
      final board = Board(rows: 6, cols: 4);
      const piece = Piece(PieceKind.bao);
      expect(board.lock(piece, 4, 0, 0), isTrue);
      expect(board.at(4, 1), PieceKind.bao);
      expect(board.at(4, 2), PieceKind.bao);
      expect(board.at(5, 1), PieceKind.bao);
      expect(board.at(5, 2), PieceKind.bao);

      // A piece locked partly above the top reports overflow.
      expect(board.lock(piece, -1, 0, 0), isFalse);
    });

    test('fullRows and removeRows collapse the stack', () {
      final board = Board(rows: 4, cols: 2);
      const piece = Piece(PieceKind.bao); // fills 2x2 at cols 1..2 -> use col -1
      board.lock(piece, 2, -1, 0); // fills rows 2,3 fully (cols 0,1)
      expect(board.fullRows(), [2, 3]);

      board.removeRows([2, 3]);
      expect(board.fullRows(), isEmpty);
      expect(board.highestOccupiedRow(), 4);
    });

    test('removeRows keeps rows above and lets them fall', () {
      final board = Board(rows: 4, cols: 2);
      const bao = Piece(PieceKind.bao);
      board.lock(bao, 2, -1, 0); // rows 2 and 3 full
      board.removeRows([3]);
      expect(board.at(3, 0), PieceKind.bao); // old row 2 fell to row 3
      expect(board.at(3, 1), PieceKind.bao);
      expect(board.at(2, 0), isNull);
    });
  });

  group('Piece', () {
    test('every rotation has exactly four cells', () {
      for (final kind in PieceKind.values) {
        final piece = Piece(kind);
        for (var r = 0; r < Piece.rotationCount; r++) {
          expect(piece.cells(r).length, 4,
              reason: '$kind rotation $r must have 4 cells');
          expect(piece.cells(r).toSet().length, 4,
              reason: '$kind rotation $r must not repeat cells');
        }
      }
    });

    test('rotating four times returns to the start', () {
      for (final kind in PieceKind.values) {
        final piece = Piece(kind);
        expect(piece.cells(4), piece.cells(0));
      }
    });

    test('width matches shape', () {
      expect(const Piece(PieceKind.po).width(0), 4);
      expect(const Piece(PieceKind.po).width(1), 1);
      expect(const Piece(PieceKind.bao).width(0), 2);
    });
  });
}
