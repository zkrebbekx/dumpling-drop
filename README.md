# Dumpling Drop 🥟

A squishy falling-block puzzle game for children, ages 5 to 10. Built
with Flutter.

Dumplings fall into a bamboo steamer. Move them, turn them, and fill a
row to make the dumplings pop. Clear the goal to win the level.

## Features

- **15 levels** across three difficulties: Steamed, Pan-Fried, and Spicy.
- **Star ratings**: each level awards 1 to 3 stars based on the score.
- **Sticker Book**: 14 collectible award stickers.
- **Kid-first design**: big buttons, a ghost landing guide, gentle
  wall kicks, a lock-delay grace period, and no harsh fail states.
- **Squishy feel**: squish animations, blink cycles, pop particles,
  steam, confetti, and a screen wiggle on a four-line "Dumpling Feast".
- **Original sound**: every sound effect is synthesized by
  `tool/gen_sounds.dart`. The game ships with zero licensed audio.
- **Fully offline**: no server, no accounts, no ads, no tracking.
  Progress is stored only on the device.

## Build

Requirements: Flutter 3.35 or newer with the Android toolchain.

```bash
flutter pub get
dart run tool/gen_sounds.dart   # only if assets/audio is missing
flutter test
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Controls

- Tap the board to rotate.
- Drag left or right to move.
- Drag down to drop the piece faster.
- Flick down to drop the piece at once.
- The four big buttons do the same actions.

## Architecture

| Path | Purpose |
|---|---|
| `lib/game/` | Pure game logic: board, pieces, controller, levels, badges, progress. No widgets. |
| `lib/widgets/` | Custom painters and animated widgets. |
| `lib/screens/` | Home, level map, game, and sticker book screens. |
| `lib/audio/` | The sound-effect player. |
| `tool/gen_sounds.dart` | Synthesizes all WAV assets. |
| `test/tools/gen_icon_test.dart` | Renders the launcher icon from the app's own painter. |

The game logic in `lib/game/` has no dependency on Flutter widgets, so
the whole rule set is unit-tested.

## Privacy

The app collects nothing. It has no analytics and no third-party
services. It is safe to hand to a child.

## License

MIT for the code. The Baloo 2 font is under the SIL Open Font License
(see `assets/fonts/OFL.txt`).
