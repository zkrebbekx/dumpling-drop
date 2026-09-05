import 'package:flutter/material.dart';

import '../game/levels.dart';
import '../game/progress_store.dart';
import '../theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/steam_background.dart';
import 'game_screen.dart';

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
      MaterialPageRoute(
        builder: (_) => GameScreen(level: level, store: widget.store),
      ),
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
                    for (final entry in byDifficulty.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 10),
                        child: Row(
                          children: [
                            Text(entry.key.emoji,
                                style: const TextStyle(fontSize: 26)),
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
                          for (final level in entry.value)
                            _LevelNode(
                              level: level,
                              stars: store.starsFor(level.number),
                              unlocked: store.isUnlocked(level.number),
                              color: _difficultyColors[entry.key]!,
                              onTap: () => _play(level),
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

class _LevelNode extends StatelessWidget {
  final LevelConfig level;
  final int stars;
  final bool unlocked;
  final Color color;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          unlocked
              ? Text('${level.number}',
                  style: DumplingTheme.display(size: 34))
              : Icon(Icons.lock_rounded,
                  size: 34,
                  color: DumplingTheme.ink.withValues(alpha: 0.3)),
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
