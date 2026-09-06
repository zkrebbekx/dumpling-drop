import 'package:flutter/material.dart';

import '../game/piece.dart';
import '../theme.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/dumpling.dart';
import '../widgets/steam_background.dart';

/// Meet the Dumplings: one card per piece, with a name and a line.
/// Kids bond with named characters; this page gives the cast a home.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  static const _bios = {
    PieceKind.po: 'Long and brave. Po fills big gaps in one go!',
    PieceKind.bao: 'Round and cozy. Bao fits snug in corners.',
    PieceKind.mei: 'Sweet and pointy. Mei pokes into tricky spots.',
    PieceKind.edamame: 'A little zig. Eda loves the wiggly stacks.',
    PieceKind.gyoza: 'A little zag. Gyo is Eda\'s mirror twin.',
    PieceKind.ube: 'Purple power! Ube hooks around the edges.',
    PieceKind.veggie: 'Full of greens. Veg hooks the other way.',
  };

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
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: DumplingTheme.fillings[kind.index],
                            width: 3,
                          ),
                        ),
                        child: Row(
                          children: [
                            DumplingMascot(
                              size: 72,
                              color: DumplingTheme.fillings[kind.index],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(kind.fullName,
                                      style:
                                          DumplingTheme.display(size: 22)),
                                  Text(
                                    _bios[kind]!,
                                    style: DumplingTheme.body(
                                        size: 15,
                                        color: DumplingTheme.inkSoft),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
