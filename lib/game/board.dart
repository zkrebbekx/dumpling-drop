import 'piece.dart';

/// The play field. Holds locked dumplings.
///
/// Each cell stores the [PieceKind] of the dumpling that rests there,
/// or null when the cell is empty. Row 0 is the top row.
class Board {
  final int rows;
  final int cols;
  final List<List<PieceKind?>> _grid;

  Board({required this.rows, required this.cols})
      : _grid = List.generate(rows, (_) => List.filled(cols, null));

  PieceKind? at(int row, int col) => _grid[row][col];

  bool inBounds(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  /// True when the piece fits at (row, col) with the given rotation.
  ///
  /// Cells above the top of the board are allowed. This lets a new piece
  /// enter the board from above.
  bool canPlace(Piece piece, int row, int col, int rotation) {
    for (final cell in piece.cells(rotation)) {
      final r = row + cell.row;
      final c = col + cell.col;
      if (c < 0 || c >= cols || r >= rows) return false;
      if (r >= 0 && _grid[r][c] != null) return false;
    }
    return true;
  }

  /// Locks the piece into the grid.
  ///
  /// Returns false when any cell of the piece sits above the board,
  /// which means the board is full (game over).
  bool lock(Piece piece, int row, int col, int rotation) {
    var allInside = true;
    for (final cell in piece.cells(rotation)) {
      final r = row + cell.row;
      final c = col + cell.col;
      if (r < 0) {
        allInside = false;
        continue;
      }
      _grid[r][c] = piece.kind;
    }
    return allInside;
  }

  /// Row indexes that are completely full, top to bottom.
  List<int> fullRows() {
    final full = <int>[];
    for (var r = 0; r < rows; r++) {
      if (_grid[r].every((cell) => cell != null)) full.add(r);
    }
    return full;
  }

  /// Removes the given rows and lets everything above fall down.
  void removeRows(List<int> rowIndexes) {
    final remove = rowIndexes.toSet();
    final kept = <List<PieceKind?>>[];
    for (var r = 0; r < rows; r++) {
      if (!remove.contains(r)) kept.add(_grid[r]);
    }
    final missing = rows - kept.length;
    _grid.setAll(
      0,
      [
        for (var i = 0; i < missing; i++) List<PieceKind?>.filled(cols, null),
        ...kept,
      ],
    );
  }

  /// Highest occupied row index, or [rows] when the board is empty.
  int highestOccupiedRow() {
    for (var r = 0; r < rows; r++) {
      if (_grid[r].any((cell) => cell != null)) return r;
    }
    return rows;
  }

  void clear() {
    for (final row in _grid) {
      row.fillRange(0, cols, null);
    }
  }
}
