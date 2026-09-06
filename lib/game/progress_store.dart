import 'package:shared_preferences/shared_preferences.dart';

import 'badges.dart';
import 'levels.dart';

/// Saves progress on the device. No network, no accounts.
class ProgressStore {
  final SharedPreferences _prefs;

  ProgressStore(this._prefs);

  static Future<ProgressStore> open() async {
    return ProgressStore(await SharedPreferences.getInstance());
  }

  // ---- Settings ----

  bool get soundOn => _prefs.getBool('soundOn') ?? true;
  Future<void> setSoundOn(bool value) => _prefs.setBool('soundOn', value);

  // ---- Level progress ----

  int starsFor(int levelNumber) => _prefs.getInt('stars.$levelNumber') ?? 0;

  int bestScoreFor(int levelNumber) =>
      _prefs.getInt('best.$levelNumber') ?? 0;

  /// A level is playable when it is level 1 or the level before it
  /// has at least one star.
  bool isUnlocked(int levelNumber) =>
      levelNumber == 1 || starsFor(levelNumber - 1) > 0;

  int get totalStars {
    var sum = 0;
    for (final level in levels) {
      sum += starsFor(level.number);
    }
    return sum;
  }

  Future<void> recordWin(int levelNumber, int stars, int score) async {
    if (stars > starsFor(levelNumber)) {
      await _prefs.setInt('stars.$levelNumber', stars);
    }
    await recordBestScore(levelNumber, score);
  }

  /// Keeps the best score for any level, including endless baskets.
  Future<void> recordBestScore(int levelNumber, int score) async {
    if (score > bestScoreFor(levelNumber)) {
      await _prefs.setInt('best.$levelNumber', score);
    }
  }

  // ---- Lifetime stats ----

  int get totalLines => _prefs.getInt('total.lines') ?? 0;
  int get totalGames => _prefs.getInt('total.games') ?? 0;
  int get totalFeasts => _prefs.getInt('total.feasts') ?? 0;
  int get bestCombo => _prefs.getInt('total.bestCombo') ?? 0;
  int get specialsPlayed => _prefs.getInt('total.specials') ?? 0;

  Future<void> recordGame({
    required int lines,
    required int feasts,
    required int maxCombo,
    bool special = false,
  }) async {
    await _prefs.setInt('total.lines', totalLines + lines);
    await _prefs.setInt('total.games', totalGames + 1);
    await _prefs.setInt('total.feasts', totalFeasts + feasts);
    if (special) {
      await _prefs.setInt('total.specials', specialsPlayed + 1);
    }
    if (maxCombo > bestCombo) {
      await _prefs.setInt('total.bestCombo', maxCombo);
    }
  }

  // ---- Badges ----

  bool hasBadge(String id) => _prefs.getBool('badge.$id') ?? false;

  Set<String> get ownedBadges =>
      {for (final b in allBadges) if (hasBadge(b.id)) b.id};

  /// Grants any newly earned badges. Returns the new ones so the UI
  /// can celebrate them.
  Future<List<Badge>> grantNewBadges(BadgeStats stats) async {
    final earned = earnedBadges(stats);
    final fresh = <Badge>[];
    for (final badge in allBadges) {
      if (earned.contains(badge.id) && !hasBadge(badge.id)) {
        await _prefs.setBool('badge.${badge.id}', true);
        fresh.add(badge);
      }
    }
    return fresh;
  }

  /// Levels won per difficulty plus star counts, for badge checks.
  BadgeStats statsSnapshot({
    int gameLines = 0,
    int gameBestClear = 0,
    int gameScore = 0,
  }) {
    var easyWon = 0, mediumWon = 0, hardWon = 0, threeStar = 0;
    for (final level in levels) {
      final stars = starsFor(level.number);
      if (stars > 0) {
        switch (level.difficulty) {
          case Difficulty.easy:
            easyWon++;
          case Difficulty.medium:
            mediumWon++;
          case Difficulty.hard:
            hardWon++;
        }
      }
      if (stars >= 3) threeStar++;
    }
    return BadgeStats(
      totalLines: totalLines,
      totalGames: totalGames,
      totalFeasts: totalFeasts,
      bestCombo: bestCombo,
      specialsPlayed: specialsPlayed,
      gameLines: gameLines,
      gameBestClear: gameBestClear,
      gameScore: gameScore,
      easyLevelsWon: easyWon,
      mediumLevelsWon: mediumWon,
      hardLevelsWon: hardWon,
      threeStarLevels: threeStar,
    );
  }
}
