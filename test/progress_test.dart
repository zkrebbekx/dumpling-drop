import 'package:dumpling_drop/game/badges.dart';
import 'package:dumpling_drop/game/characters.dart';
import 'package:dumpling_drop/game/piece.dart';
import 'package:dumpling_drop/game/levels.dart';
import 'package:dumpling_drop/game/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressStore', () {
    late ProgressStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = ProgressStore(await SharedPreferences.getInstance());
    });

    test('only level 1 starts unlocked', () {
      expect(store.isUnlocked(1), isTrue);
      expect(store.isUnlocked(2), isFalse);
      expect(store.isUnlocked(15), isFalse);
    });

    test('a win unlocks the next level and keeps the best result', () async {
      await store.recordWin(1, 2, 500);
      expect(store.starsFor(1), 2);
      expect(store.bestScoreFor(1), 500);
      expect(store.isUnlocked(2), isTrue);

      // A worse run must not lower the record.
      await store.recordWin(1, 1, 300);
      expect(store.starsFor(1), 2);
      expect(store.bestScoreFor(1), 500);

      // A better run raises it.
      await store.recordWin(1, 3, 900);
      expect(store.starsFor(1), 3);
      expect(store.totalStars, 3);
    });

    test('recordGame accumulates lifetime stats', () async {
      await store.recordGame(lines: 5, feasts: 1, maxCombo: 2);
      await store.recordGame(lines: 7, feasts: 0, maxCombo: 4);
      expect(store.totalLines, 12);
      expect(store.totalGames, 2);
      expect(store.totalFeasts, 1);
      expect(store.bestCombo, 4);
    });

    test('grantNewBadges grants each badge once', () async {
      await store.recordGame(lines: 3, feasts: 0, maxCombo: 1);
      final first = await store.grantNewBadges(
          store.statsSnapshot(gameLines: 3, gameBestClear: 1));
      expect(first.map((b) => b.id), contains('first_line'));

      final second = await store.grantNewBadges(
          store.statsSnapshot(gameLines: 3, gameBestClear: 1));
      expect(second, isEmpty);
      expect(store.hasBadge('first_line'), isTrue);
    });
  });

  group('earnedBadges', () {
    test('empty stats earn nothing', () {
      expect(earnedBadges(const BadgeStats()), isEmpty);
    });

    test('a feast earns the feast family', () {
      final earned = earnedBadges(const BadgeStats(
        totalLines: 4,
        gameBestClear: 4,
      ));
      expect(earned, containsAll(['first_line', 'double', 'triple', 'feast']));
    });

    test('finishing every level with three stars earns golden', () {
      final earned = earnedBadges(const BadgeStats(
        totalLines: 300,
        totalGames: 40,
        easyLevelsWon: 5,
        mediumLevelsWon: 5,
        hardLevelsWon: 5,
        threeStarLevels: 15,
      ));
      expect(
          earned,
          containsAll(
              ['steam_champ', 'pan_master', 'spice_legend', 'golden']));
    });
  });

  group('levels', () {
    test('there are 15 levels numbered in order', () {
      expect(levels.length, 15);
      for (var i = 0; i < levels.length; i++) {
        expect(levels[i].number, i + 1);
      }
    });

    test('difficulty rises: later levels are faster', () {
      expect(levels.first.gravity.inMilliseconds,
          greaterThan(levels.last.gravity.inMilliseconds));
      for (final level in levels) {
        expect(level.goalLines, greaterThan(0));
        expect(level.cols, greaterThanOrEqualTo(8));
        expect(level.pieceKinds, isNotEmpty);
        expect(level.threeStarScore, greaterThan(level.twoStarScore));
      }
    });

    test('five levels per difficulty', () {
      for (final difficulty in Difficulty.values) {
        expect(levels.where((l) => l.difficulty == difficulty).length, 5);
      }
    });
  });

  group("Today's Special", () {
    test('is deterministic for a given day', () {
      final date = DateTime(2026, 9, 6, 14, 30);
      final a = todaysSpecial(date);
      final b = todaysSpecial(DateTime(2026, 9, 6, 8, 0));
      expect(a.number, b.number);
      expect(a.cols, b.cols);
      expect(a.goalLines, b.goalLines);
      expect(a.gravity, b.gravity);
      expect(isSpecialLevel(a.number), isTrue);
      expect(isSpecialLevel(1), isFalse);
    });

    test('changes from one day to the next', () {
      final today = todaysSpecial(DateTime(2026, 9, 6));
      final tomorrow = todaysSpecial(DateTime(2026, 9, 7));
      expect(today.number, isNot(tomorrow.number));
    });

    test('stays inside sane bounds across a year', () {
      for (var i = 0; i < 366; i++) {
        final special =
            todaysSpecial(DateTime(2026, 1, 1).add(Duration(days: i)));
        expect(special.cols, inInclusiveRange(8, 10));
        expect(special.goalLines, inInclusiveRange(6, 14));
        expect(special.gravity.inMilliseconds, inInclusiveRange(500, 819));
        expect(special.pieceKinds, isNotEmpty);
      }
    });

    test('playing specials counts toward the special badges', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ProgressStore(await SharedPreferences.getInstance());
      await store.recordGame(
          lines: 3, feasts: 0, maxCombo: 1, special: true);
      expect(store.specialsPlayed, 1);
      final earned = earnedBadges(store.statsSnapshot());
      expect(earned, contains('special'));
      expect(earned, isNot(contains('special5')));
    });
  });
  group('characters', () {
    test('every piece kind has a complete character card', () {
      for (final kind in PieceKind.values) {
        final info = characters[kind];
        expect(info, isNotNull, reason: '$kind needs a character');
        expect(info!.name, isNotEmpty);
        expect(info.type, isNotEmpty);
        expect(info.bio, isNotEmpty);
        expect(info.likes, isNotEmpty);
        expect(info.move, isNotEmpty);
      }
    });
  });
}
