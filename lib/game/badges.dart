/// Sticker awards. Kids collect these in the Sticker Book.
class Badge {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const Badge(this.id, this.name, this.emoji, this.description);
}

/// A snapshot of everything a badge check may need.
class BadgeStats {
  // Lifetime totals.
  final int totalLines;
  final int totalGames;
  final int totalFeasts;
  final int bestCombo;
  final int specialsPlayed;

  // Latest finished game.
  final int gameLines;
  final int gameBestClear; // most lines in a single clear this game
  final int gameScore;

  // Level progress.
  final int easyLevelsWon;
  final int mediumLevelsWon;
  final int hardLevelsWon;
  final int threeStarLevels;

  const BadgeStats({
    this.totalLines = 0,
    this.totalGames = 0,
    this.totalFeasts = 0,
    this.bestCombo = 0,
    this.specialsPlayed = 0,
    this.gameLines = 0,
    this.gameBestClear = 0,
    this.gameScore = 0,
    this.easyLevelsWon = 0,
    this.mediumLevelsWon = 0,
    this.hardLevelsWon = 0,
    this.threeStarLevels = 0,
  });
}

const allBadges = <Badge>[
  Badge('first_line', 'First Bite', '🥟', 'Clear your first line'),
  Badge('double', 'Double Yum', '😋', 'Clear 2 lines at once'),
  Badge('triple', 'Triple Treat', '🎉', 'Clear 3 lines at once'),
  Badge('feast', 'Dumpling Feast', '🍽️', 'Clear 4 lines at once'),
  Badge('combo3', 'Chef Combo', '🔥', 'Clear lines 3 drops in a row'),
  Badge('score3k', 'Big Appetite', '🍜', 'Score 3000 in one game'),
  Badge('lines50', 'Line Cook', '👨‍🍳', 'Clear 50 lines in total'),
  Badge('lines200', 'Sous Chef', '⭐', 'Clear 200 lines in total'),
  Badge('games10', 'Hungry Ten', '🐼', 'Play 10 games'),
  Badge('star3', 'Star Chef', '🌟', 'Earn 3 stars on a level'),
  Badge('special', 'Daily Taster', '📅', "Play a Today's Special"),
  Badge('special5', 'Regular', '🍽️', "Play 5 Today's Specials"),
  Badge('steam_champ', 'Steam Champion', '☁️', 'Finish all Steamed levels'),
  Badge('pan_master', 'Pan Master', '🍳', 'Finish all Pan-Fried levels'),
  Badge('spice_legend', 'Spice Legend', '🌶️', 'Finish all Spicy levels'),
  Badge('golden', 'Golden Chopsticks', '🥇', '3 stars on every level'),
];

/// Which badges the stats earn. Pure and easy to test.
Set<String> earnedBadges(BadgeStats s) {
  final earned = <String>{};
  void grant(String id, bool when) {
    if (when) earned.add(id);
  }

  grant('first_line', s.totalLines >= 1);
  grant('double', s.gameBestClear >= 2);
  grant('triple', s.gameBestClear >= 3);
  grant('feast', s.gameBestClear >= 4 || s.totalFeasts >= 1);
  grant('combo3', s.bestCombo >= 3);
  grant('score3k', s.gameScore >= 3000);
  grant('lines50', s.totalLines >= 50);
  grant('lines200', s.totalLines >= 200);
  grant('games10', s.totalGames >= 10);
  grant('star3', s.threeStarLevels >= 1);
  grant('special', s.specialsPlayed >= 1);
  grant('special5', s.specialsPlayed >= 5);
  grant('steam_champ', s.easyLevelsWon >= 5);
  grant('pan_master', s.mediumLevelsWon >= 5);
  grant('spice_legend', s.hardLevelsWon >= 5);
  grant('golden', s.threeStarLevels >= 15);
  return earned;
}
