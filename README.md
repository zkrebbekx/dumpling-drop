# Dumpling Drop 🥟

A squishy falling-block puzzle game for children, ages 5 to 10. Built
with Flutter.

Dumplings fall into a bamboo steamer. Move them, turn them, and fill a
row to make the dumplings pop. Clear the goal to win the level.

## Features

- **15 levels** across three difficulties: Steamed, Pan-Fried, and
  Spicy, plus three **endless Free Play** baskets.
- **Today's Special**: one fresh challenge per day, seeded from the
  date, so it needs no server.
- **Star ratings**: each level awards 1 to 3 stars based on the score,
  with visible score targets.
- **Sticker Book**: 16 collectible award stickers with hand-painted
  medallion art.
- **A real cast**: the seven pieces are characters with signature
  looks — Mei the unicorn (horn and rainbow mane), Ube the glitter
  dreamer, Gyo with a flame tuft, Po in sunglasses, Eda the sprout,
  Veg the ninja, and Bao the classic. Each has a type, a bio, likes,
  and a signature move on its collectible card in Meet the Dumplings.
  Mei lands in a burst of rainbow sparkles; Ube lands in glitter.
- **Kid-first design**: big hold-to-repeat buttons, a ghost landing
  guide, gentle wall kicks, a lock-delay grace period, gesture hints,
  a head-start retry on long levels, and no harsh fail states.
- **Squishy feel**: squish animations, blink cycles, lean-while-moving,
  eyes that watch the landing spot, pop particles, floating score
  text, rising combo pitch, haptics, steam puffs from the stack,
  impact dust on hard drops, confetti, and a screen wiggle on a
  four-line "Dumpling Feast".
- **One art style everywhere**: a painted in-game icon set, bouncy
  screen transitions, staggered pop-in menus, and a score count-up.
  Every animation honors the platform reduced-motion setting.
- **Original sound**: every sound effect and the music loop are
  synthesized by `tool/gen_sounds.dart`. The game ships with zero
  licensed audio.
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
