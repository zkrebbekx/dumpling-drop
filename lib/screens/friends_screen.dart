import 'package:flutter/material.dart';

import '../game/characters.dart';
import '../game/piece.dart';
import '../theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/dumpling.dart';
import '../widgets/motion.dart';
import '../widgets/steam_background.dart';

/// Meet the Dumplings: a collectible-style card per character, with
/// a type, a story, likes, and a signature move. Kids bond with named
/// characters; this page gives the cast a home.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Text('The Dumplings',
                        style: DumplingTheme.display(size: 30)),
                    const Spacer(),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final kind in PieceKind.values)
                      PopIn(
                        delay:
                            Duration(milliseconds: 40 + kind.index * 55),
                        child: _CharacterCard(kind: kind),
                      ),
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

class _CharacterCard extends StatelessWidget {
  final PieceKind kind;

  const _CharacterCard({required this.kind});

  @override
  Widget build(BuildContext context) {
    final info = characters[kind]!;
    final bodyColor = DumplingBodyColors.of(kind);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            bodyColor.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: info.typeColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: info.typeColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DumplingMascot(size: 86, kind: kind),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(info.name,
                            style: DumplingTheme.display(size: 26)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            info.title,
                            overflow: TextOverflow.ellipsis,
                            style: DumplingTheme.body(
                                size: 15, color: DumplingTheme.inkSoft),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: info.typeColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${info.type} type',
                        style: DumplingTheme.body(
                            size: 14, color: Colors.white, weight: 700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(info.bio, style: DumplingTheme.body(size: 15)),
          const SizedBox(height: 8),
          _fact('Likes', info.likes, info.typeColor),
          const SizedBox(height: 4),
          _fact('Move', info.move, info.typeColor),
        ],
      ),
    );
  }

  Widget _fact(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: DumplingTheme.body(
                  size: 13, color: DumplingTheme.inkSoft, weight: 700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: DumplingTheme.body(size: 14)),
        ),
      ],
    );
  }
}
