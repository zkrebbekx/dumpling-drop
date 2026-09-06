import 'dart:math';

import 'piece.dart';

enum Difficulty {
  easy('Steamed', '🥟'),
  medium('Pan-Fried', '🍳'),
  hard('Spicy', '🌶️');

  final String label;
  final String emoji;
  const Difficulty(this.label, this.emoji);
}

/// The rules for one level.
class LevelConfig {
  /// 1-based level number.
  final int number;
  final String name;
  final Difficulty difficulty;
  final int rows;
  final int cols;

  /// How long a piece waits before it falls one row, at the start.
  final Duration gravity;

  /// Clear this many lines to win the level.
  final int goalLines;

  /// Piece kinds that appear in this level. Early levels skip the
  /// tricky S and Z shapes so young players can settle in.
  final List<PieceKind> pieceKinds;

  /// Score needed for two and three stars.
  final int twoStarScore;
  final int threeStarScore;

  /// Endless free play: no goal, no win, gravity ramps up slowly.
  final bool endless;

  const LevelConfig({
    required this.number,
    required this.name,
    required this.difficulty,
    required this.rows,
    required this.cols,
    required this.gravity,
    required this.goalLines,
    required this.pieceKinds,
    required this.twoStarScore,
    required this.threeStarScore,
    this.endless = false,
  });
}

const _friendly = [
  PieceKind.po,
  PieceKind.bao,
  PieceKind.mei,
  PieceKind.ube,
  PieceKind.veggie,
];

const _all = PieceKind.values;

/// All 15 levels, in play order.
final List<LevelConfig> levels = [
  // Steamed (easy): wide board, slow, friendly pieces.
  _level(1, 'First Bite', Difficulty.easy, 8, 950, 4, _friendly),
  _level(2, 'Bamboo Basket', Difficulty.easy, 8, 900, 6, _friendly),
  _level(3, 'Soy Dip', Difficulty.easy, 8, 850, 8, _friendly),
  _level(4, 'Sticky Rice', Difficulty.easy, 8, 800, 10, _all),
  _level(5, 'Steam Cloud', Difficulty.easy, 8, 750, 12, _all),
  // Pan-Fried (medium): standard board, quicker.
  _level(6, 'Hot Pan', Difficulty.medium, 9, 700, 12, _all),
  _level(7, 'Golden Crisp', Difficulty.medium, 9, 640, 14, _all),
  _level(8, 'Sesame Snow', Difficulty.medium, 9, 580, 16, _all),
  _level(9, 'Ginger Zing', Difficulty.medium, 9, 520, 18, _all),
  _level(10, 'Dragon Wok', Difficulty.medium, 9, 470, 20, _all),
  // Spicy (hard): full board, fast.
  _level(11, 'Chili Oil', Difficulty.hard, 10, 430, 20, _all),
  _level(12, 'Sichuan Spark', Difficulty.hard, 10, 380, 22, _all),
  _level(13, 'Fire Cracker', Difficulty.hard, 10, 330, 24, _all),
  _level(14, 'Volcano Pot', Difficulty.hard, 10, 280, 26, _all),
  _level(15, 'Dumpling Master', Difficulty.hard, 10, 240, 30, _all),
];

LevelConfig _level(
  int number,
  String name,
  Difficulty difficulty,
  int cols,
  int gravityMs,
  int goalLines,
  List<PieceKind> kinds,
) {
  return LevelConfig(
    number: number,
    name: name,
    difficulty: difficulty,
    rows: 14,
    cols: cols,
    gravity: Duration(milliseconds: gravityMs),
    goalLines: goalLines,
    pieceKinds: kinds,
    // Reward multi-line clears: two stars needs hard drops or some
    // doubles, three stars needs a few big clears.
    twoStarScore: goalLines * 130,
    threeStarScore: goalLines * 180,
  );
}

/// The number of whole days since the epoch, in local time.
int dayNumber(DateTime date) =>
    DateTime(date.year, date.month, date.day)
        .difference(DateTime(1970))
        .inDays;

/// Today's Special: one fresh challenge per day, seeded from the
/// date, so it works fully offline and every device cooks the same
/// dish on the same day.
LevelConfig todaysSpecial(DateTime date) {
  final day = dayNumber(date);
  final r = Random(day * 7919 + 17);
  final cols = 8 + r.nextInt(3);
  final goal = 6 + r.nextInt(9); // 6..14 lines
  final gravityMs = 500 + r.nextInt(320); // 500..819 ms
  final friendlyDay = r.nextBool();
  return LevelConfig(
    // A unique number per day keeps each day's best score separate.
    number: 200000 + day,
    name: "Today's Special",
    difficulty: gravityMs > 660 ? Difficulty.easy : Difficulty.medium,
    rows: 14,
    cols: cols,
    gravity: Duration(milliseconds: gravityMs),
    goalLines: goal,
    pieceKinds: friendlyDay ? _friendly : _all,
    twoStarScore: goal * 130,
    threeStarScore: goal * 180,
  );
}

/// True for the level numbers minted by [todaysSpecial].
bool isSpecialLevel(int number) => number >= 200000;

/// Endless baskets. Each one unlocks when its difficulty is beaten.
final List<LevelConfig> freePlayLevels = [
  const LevelConfig(
    number: 101,
    name: 'Snack Time',
    difficulty: Difficulty.easy,
    rows: 14,
    cols: 8,
    gravity: Duration(milliseconds: 850),
    goalLines: 999,
    pieceKinds: _friendly,
    twoStarScore: 0,
    threeStarScore: 0,
    endless: true,
  ),
  const LevelConfig(
    number: 102,
    name: 'Sizzle Time',
    difficulty: Difficulty.medium,
    rows: 14,
    cols: 9,
    gravity: Duration(milliseconds: 620),
    goalLines: 999,
    pieceKinds: _all,
    twoStarScore: 0,
    threeStarScore: 0,
    endless: true,
  ),
  const LevelConfig(
    number: 103,
    name: 'Fire Time',
    difficulty: Difficulty.hard,
    rows: 14,
    cols: 10,
    gravity: Duration(milliseconds: 420),
    goalLines: 999,
    pieceKinds: _all,
    twoStarScore: 0,
    threeStarScore: 0,
    endless: true,
  ),
];
