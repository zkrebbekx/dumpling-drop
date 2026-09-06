import 'dart:ui';

import 'piece.dart';

/// The cast. Every piece kind is a character with a type, a story,
/// and a signature move — like a pocket-monster card.
class CharacterInfo {
  final String name;
  final String title;
  final String type;
  final Color typeColor;
  final String bio;
  final String likes;
  final String move;

  const CharacterInfo({
    required this.name,
    required this.title,
    required this.type,
    required this.typeColor,
    required this.bio,
    required this.likes,
    required this.move,
  });
}

const characters = <PieceKind, CharacterInfo>{
  PieceKind.po: CharacterInfo(
    name: 'Po',
    title: 'the Long One',
    type: 'Splash',
    typeColor: Color(0xFF5AA9DC),
    bio: 'The coolest dumpling in the steamer. Po never takes the '
        'shades off — not even in the pot.',
    likes: 'Sliding into skinny gaps',
    move: 'Mega Line!',
  ),
  PieceKind.bao: CharacterInfo(
    name: 'Bao',
    title: 'the Round',
    type: 'Classic',
    typeColor: Color(0xFFE0A33C),
    bio: 'The big-hearted leader of the basket. Bao gives the best '
        'hugs and fits snug in every corner.',
    likes: 'Cozy corners and warm steam',
    move: 'Snug Fit',
  ),
  PieceKind.mei: CharacterInfo(
    name: 'Mei',
    title: 'the Unicorn',
    type: 'Rainbow',
    typeColor: Color(0xFFE86FA4),
    bio: 'A real dumpling unicorn! Mei leaves a rainbow wherever she '
        'lands and believes every stack can sparkle.',
    likes: 'Glitter, sunsets, triple clears',
    move: 'Rainbow Slam',
  ),
  PieceKind.edamame: CharacterInfo(
    name: 'Eda',
    title: 'the Sprout',
    type: 'Sprout',
    typeColor: Color(0xFF58B583),
    bio: 'A giggly zig with a fresh sprout on top. Eda grows a tiny '
        'bit every time you clear a line.',
    likes: 'Wiggly stacks and morning dew',
    move: 'Zig Zag',
  ),
  PieceKind.gyoza: CharacterInfo(
    name: 'Gyo',
    title: 'the Sizzler',
    type: 'Sizzle',
    typeColor: Color(0xFFE8703C),
    bio: 'Fired up and fearless — Eda\'s mirror twin and friendly '
        'rival. That flame on top? One hundred percent real.',
    likes: 'Hot pans and speed drops',
    move: 'Flame Flip',
  ),
  PieceKind.ube: CharacterInfo(
    name: 'Ube',
    title: 'the Dreamer',
    type: 'Glitter',
    typeColor: Color(0xFF9C7BD8),
    bio: 'A sleepy stargazer dusted with real glitter. Ube naps '
        'while falling and still lands perfectly.',
    likes: 'Naps, night skies, sparkles',
    move: 'Star Nap',
  ),
  PieceKind.veggie: CharacterInfo(
    name: 'Veg',
    title: 'the Ninja',
    type: 'Ninja',
    typeColor: Color(0xFF6E9B3D),
    bio: 'Silent. Swift. Green. Nobody ever sees Veg drop — you '
        'only hear the squish.',
    likes: 'Shadows and perfect landings',
    move: 'Shadow Drop',
  ),
};
