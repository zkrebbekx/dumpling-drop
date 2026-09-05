import 'package:flutter/material.dart' hide Badge;

import '../game/badges.dart';
import '../game/progress_store.dart';
import '../theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/steam_background.dart';

/// Every sticker the player can collect. Locked ones show as a hint.
class StickerBookScreen extends StatelessWidget {
  final ProgressStore store;

  const StickerBookScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final owned = store.ownedBadges;
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
                    Text('Sticker Book',
                        style: DumplingTheme.display(size: 30)),
                    const Spacer(),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${owned.length} of ${allBadges.length} collected',
                  style: DumplingTheme.body(
                      size: 18, color: DumplingTheme.inkSoft),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(20),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    for (final badge in allBadges)
                      _StickerTile(
                          badge: badge, owned: owned.contains(badge.id)),
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

class _StickerTile extends StatelessWidget {
  final Badge badge;
  final bool owned;

  const _StickerTile({required this.badge, required this.owned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: owned ? Colors.white : DumplingTheme.creamDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: owned
              ? DumplingTheme.star
              : DumplingTheme.ink.withValues(alpha: 0.12),
          width: 3,
        ),
        boxShadow: owned
            ? [
                BoxShadow(
                  color: DumplingTheme.star.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: owned ? 1 : 0.35,
            child: Text(badge.emoji, style: const TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 6),
          Text(
            owned ? badge.name : '???',
            textAlign: TextAlign.center,
            style: DumplingTheme.display(
              size: 18,
              color: owned
                  ? DumplingTheme.ink
                  : DumplingTheme.ink.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DumplingTheme.body(
              size: 13,
              color: DumplingTheme.inkSoft
                  .withValues(alpha: owned ? 1 : 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
