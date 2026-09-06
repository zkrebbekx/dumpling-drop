import 'dart:math';
import 'dart:ui';

/// A cell offset inside a piece, relative to the piece origin.
class Cell {
  final int row;
  final int col;
  const Cell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Cell($row,$col)';
}

/// The seven dumpling piece kinds. Each kind is a classic tetromino shape
/// dressed up as a plate of dumplings with one filling.
enum PieceKind {
  po('Po', 'Long Bao'), // I
  bao('Bao', 'Big Bun'), // O
  mei('Mei', 'Sweet Mei'), // T
  edamame('Eda', 'Edamame'), // S
  gyoza('Gyo', 'Gyoza'), // Z
  ube('Ube', 'Ube Bun'), // J
  veggie('Veg', 'Veggie'); // L

  final String shortName;
  final String fullName;
  const PieceKind(this.shortName, this.fullName);
}

/// Static shape data: rotations for each kind.
///
/// Each rotation is a list of 4 cells in a 4x4 box. Rotations are
/// precomputed so game logic stays simple and testable.
class Piece {
  final PieceKind kind;

  const Piece(this.kind);

  static const Map<PieceKind, List<List<Cell>>> _rotations = {
    PieceKind.po: [
      [Cell(1, 0), Cell(1, 1), Cell(1, 2), Cell(1, 3)],
      [Cell(0, 2), Cell(1, 2), Cell(2, 2), Cell(3, 2)],
      [Cell(2, 0), Cell(2, 1), Cell(2, 2), Cell(2, 3)],
      [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(3, 1)],
    ],
    PieceKind.bao: [
      [Cell(0, 1), Cell(0, 2), Cell(1, 1), Cell(1, 2)],
      [Cell(0, 1), Cell(0, 2), Cell(1, 1), Cell(1, 2)],
      [Cell(0, 1), Cell(0, 2), Cell(1, 1), Cell(1, 2)],
      [Cell(0, 1), Cell(0, 2), Cell(1, 1), Cell(1, 2)],
    ],
    PieceKind.mei: [
      [Cell(0, 1), Cell(1, 0), Cell(1, 1), Cell(1, 2)],
      [Cell(0, 1), Cell(1, 1), Cell(1, 2), Cell(2, 1)],
      [Cell(1, 0), Cell(1, 1), Cell(1, 2), Cell(2, 1)],
      [Cell(0, 1), Cell(1, 0), Cell(1, 1), Cell(2, 1)],
    ],
    PieceKind.edamame: [
      [Cell(0, 1), Cell(0, 2), Cell(1, 0), Cell(1, 1)],
      [Cell(0, 1), Cell(1, 1), Cell(1, 2), Cell(2, 2)],
      [Cell(1, 1), Cell(1, 2), Cell(2, 0), Cell(2, 1)],
      [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(2, 1)],
    ],
    PieceKind.gyoza: [
      [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 2)],
      [Cell(0, 2), Cell(1, 1), Cell(1, 2), Cell(2, 1)],
      [Cell(1, 0), Cell(1, 1), Cell(2, 1), Cell(2, 2)],
      [Cell(0, 1), Cell(1, 0), Cell(1, 1), Cell(2, 0)],
    ],
    PieceKind.ube: [
      [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(1, 2)],
      [Cell(0, 1), Cell(0, 2), Cell(1, 1), Cell(2, 1)],
      [Cell(1, 0), Cell(1, 1), Cell(1, 2), Cell(2, 2)],
      [Cell(0, 1), Cell(1, 1), Cell(2, 0), Cell(2, 1)],
    ],
    PieceKind.veggie: [
      [Cell(0, 2), Cell(1, 0), Cell(1, 1), Cell(1, 2)],
      [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(2, 2)],
      [Cell(1, 0), Cell(1, 1), Cell(1, 2), Cell(2, 0)],
      [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
    ],
  };

  /// Number of distinct rotation states.
  static const int rotationCount = 4;

  /// The cells of this piece at [rotation] (0..3).
  List<Cell> cells(int rotation) =>
      _rotations[kind]![rotation % rotationCount];

  /// The color of this piece's dumplings.
  Color color(List<Color> palette) => palette[kind.index];

  /// Width in columns at [rotation].
  int width(int rotation) {
    final cs = cells(rotation);
    return cs.map((c) => c.col).reduce(max) -
        cs.map((c) => c.col).reduce(min) +
        1;
  }

  /// Smallest column offset inside the bounding box at [rotation].
  int minCol(int rotation) =>
      cells(rotation).map((c) => c.col).reduce(min);

  /// Largest row offset inside the bounding box at [rotation].
  int maxRow(int rotation) =>
      cells(rotation).map((c) => c.row).reduce(max);
}
