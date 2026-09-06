import 'package:flutter/material.dart';

import '../game/levels.dart';
import '../game/progress_store.dart';
import '../theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/motion.dart';
import '../widgets/painted_icons.dart';
import '../widgets/steam_background.dart';
import 'game_screen.dart';

const _difficultyIcons = {
  Difficulty.easy: GameIcon.steamer,
  Difficulty.medium: GameIcon.pan,
  Difficulty.hard: GameIcon.chili,
};

/// Pick a level. Levels sit on a winding path, grouped by difficulty.
class LevelMapScreen extends StatefulWidget {
  final ProgressStore store;

  const LevelMapScreen({super.key, required this.store});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  static const _difficultyColors = {
    Difficulty.easy: DumplingTheme.mint,
    Difficulty.medium: DumplingTheme.lemon,
    Difficulty.hard: DumplingTheme.pink,
  };

  Future<void> _play(LevelConfig level) async {
    await Navigator.of(context).push(
      bouncyRoute(GameScreen(level: level, store: widget.store)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final byDifficulty = <Difficulty, List<LevelConfig>>{};
    for (final level in levels) {
      byDifficulty.putIfAbsent(level.difficulty, () => []).add(level);
    }

    return Scaffold(
      body: SteamBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    BouncyIconButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back',
                      color: DumplingTheme.lemon,
                      size: 52,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text('Pick a Basket!',
                        style: DumplingTheme.display(size: 30)),
                    const Spacer(),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  children: [
                    PopIn(
                        child: _SpecialCard(store: store, onPlay: _play)),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 10),
                      child: Row(
                        children: [
                          const PaintedIcon(GameIcon.bento, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Free Play',
                            style: DumplingTheme.display(
                                size: 26, color: DumplingTheme.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (var i = 0; i < freePlayLevels.length; i++)
                          PopIn(
                            delay: Duration(milliseconds: 60 + i * 50),
                            child: _LevelNode(
                              level: freePlayLevels[i],
                              stars: 0,
                              best: store
                                  .bestScoreFor(freePlayLevels[i].number),
                              // Each basket opens when its difficulty
                              // tier is beaten: levels 5, 10, 15.
                              unlocked: store.starsFor((i + 1) * 5) > 0,
                              color: _difficultyColors[
                                  freePlayLevels[i].difficulty]!,
                              onTap: () => _play(freePlayLevels[i]),
                            ),
                          ),
                      ],
                    ),
                    for (final entry in byDifficulty.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 10),
                        child: Row(
                          children: [
                            PaintedIcon(_difficultyIcons[entry.key]!,
                                size: 28),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.label,
                              style: DumplingTheme.display(
                                  size: 26, color: DumplingTheme.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final (i, level) in entry.value.indexed)
                            PopIn(
                              delay:
                                  Duration(milliseconds: 120 + i * 45),
                              child: _LevelNode(
                                level: level,
                                stars: store.starsFor(level.number),
                                unlocked: store.isUnlocked(level.number),
                                color: _difficultyColors[entry.key]!,
                                onTap: () => _play(level),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A featured card for the daily challenge. Fresh every day, seeded
/// from the date, no network needed.
class _SpecialCard extends StatelessWidget {
  final ProgressStore store;
  final Future<void> Function(LevelConfig) onPlay;

  const _SpecialCard({required this.store, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final special = todaysSpecial(DateTime.now());
    final unlocked = store.starsFor(1) > 0;
    final stars = store.starsFor(special.number);
    final content = Row(
      children: [
        const PaintedIcon(GameIcon.sun, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Special",
                  style: DumplingTheme.display(size: 22)),
              Text(
                unlocked
                    ? 'Clear ${special.goalLines} lines · '
                        '${special.cols} wide · new every day!'
                    : 'Win Level 1 to unlock',
                style: DumplingTheme.body(
                    size: 14, color: DumplingTheme.inkSoft),
              ),
            ],
          ),
        ),
        if (unlocked && stars > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < stars; i++)
                const Icon(Icons.star_rounded,
                    size: 20, color: DumplingTheme.star),
            ],
          )
        else if (!unlocked)
          Icon(Icons.lock_rounded,
              size: 28, color: DumplingTheme.ink.withValues(alpha: 0.3)),
      ],
    );

    if (!unlocked) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DumplingTheme.creamDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: DumplingTheme.ink.withValues(alpha: 0.1), width: 3),
        ),
        child: content,
      );
    }
    return BouncyButton(
      color: DumplingTheme.star,
      padding: const EdgeInsets.all(14),
      onPressed: () => onPlay(special),
      child: content,
    );
  }
}

class _LevelNode extends StatelessWidget {
  final LevelConfig level;
  final int stars;
  final bool unlocked;
  final Color color;
  final VoidCallback onTap;

  /// Free-play baskets show a best score instead of stars.
  final int? best;

  const _LevelNode({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.color,
    required this.onTap,
    this.best,
  });

  @override
  Widget build(BuildContext context) {
    final endless = level.endless;
    final content = SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          !unlocked
              ? Icon(Icons.lock_rounded,
                  size: 34,
                  color: DumplingTheme.ink.withValues(alpha: 0.3))
              : endless
                  ? PaintedIcon(_difficultyIcons[level.difficulty]!,
                      size: 32)
                  : Text('${level.number}',
                      style: DumplingTheme.display(size: 34)),
          Text(
            level.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DumplingTheme.body(
              size: 13,
              color: unlocked
                  ? DumplingTheme.ink
                  : DumplingTheme.ink.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 4),
          if (endless)
            Text(
              best != null && best! > 0 ? 'Best $best' : 'Endless!',
              style: DumplingTheme.body(
                size: 13,
                color: unlocked
                    ? DumplingTheme.ink
                    : DumplingTheme.ink.withValues(alpha: 0.35),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: i < stars
                        ? DumplingTheme.star
                        : DumplingTheme.ink.withValues(alpha: 0.15),
                  ),
              ],
            ),
        ],
      ),
    );

    if (!unlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: DumplingTheme.creamDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: DumplingTheme.ink.withValues(alpha: 0.1),
            width: 3,
          ),
        ),
        child: content,
      );
    }
    return BouncyButton(
      onPressed: onTap,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: content,
    );
  }
}
