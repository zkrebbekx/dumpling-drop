import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../game/badges.dart';
import '../game/piece.dart';
import '../game/progress_store.dart';
import '../theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/dumpling.dart';
import '../widgets/motion.dart';
import '../widgets/painted_icons.dart';
import '../widgets/steam_background.dart';
import 'friends_screen.dart';
import 'level_map_screen.dart';
import 'sticker_book_screen.dart';

class HomeScreen extends StatefulWidget {
  final ProgressStore store;

  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      body: SteamBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: BouncyIconButton(
                    icon: store.soundOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: DumplingTheme.lemon,
                    size: 52,
                    label:
                        store.soundOn ? 'Turn sound off' : 'Turn sound on',
                    onPressed: () async {
                      final next = !store.soundOn;
                      await store.setSoundOn(next);
                      Sfx.instance.setEnabled(next);
                      if (next) {
                        Sfx.instance.play(Sound.click);
                        await Sfx.instance.startMusic();
                      }
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  // Scales the hero art down on short screens instead
                  // of overflowing.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Dumpling',
                          style: DumplingTheme.display(size: 56).copyWith(
                              color: DumplingTheme.ink,
                              shadows: const [
                                Shadow(
                                    color: Colors.white,
                                    offset: Offset(0, 3),
                                    blurRadius: 0)
                              ]),
                        ),
                        Sway(
                          radians: 0.03,
                          child: Text(
                            'DROP!',
                            style: DumplingTheme.display(size: 72).copyWith(
                              color: DumplingTheme.peach,
                              shadows: const [
                                Shadow(
                                    color: Color(0xFFB9854A),
                                    offset: Offset(0, 4),
                                    blurRadius: 0),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DumplingMascot(size: 76, kind: PieceKind.gyoza),
                            SizedBox(width: 8),
                            DumplingMascot(size: 110, kind: PieceKind.mei),
                            SizedBox(width: 8),
                            DumplingMascot(size: 76, kind: PieceKind.ube),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BouncyButton(
                color: DumplingTheme.mint,
                padding:
                    const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                onPressed: () => Navigator.of(context)
                    .push(bouncyRoute(LevelMapScreen(store: store)))
                    .then((_) => setState(() {})),
                child: Text('PLAY!',
                    style: DumplingTheme.display(size: 36)),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BouncyButton(
                    color: DumplingTheme.pink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    onPressed: () => Navigator.of(context)
                        .push(bouncyRoute(StickerBookScreen(store: store)))
                        .then((_) => setState(() {})),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PaintedIcon(GameIcon.book, size: 26),
                        const SizedBox(width: 8),
                        Text('Stickers',
                            style: DumplingTheme.display(size: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  BouncyButton(
                    color: DumplingTheme.lilac,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    onPressed: () => Navigator.of(context)
                        .push(bouncyRoute(const FriendsScreen())),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PaintedIcon(GameIcon.dumpling, size: 24),
                        const SizedBox(width: 8),
                        Text('Friends',
                            style: DumplingTheme.display(size: 22)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      color: DumplingTheme.star, size: 30),
                  const SizedBox(width: 6),
                  Text(
                    '${store.totalStars} / 45   ·   '
                    '${store.ownedBadges.length} / ${allBadges.length} stickers',
                    style: DumplingTheme.body(
                        size: 18, color: DumplingTheme.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
