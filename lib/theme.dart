import 'package:flutter/material.dart';

/// The visual language of Dumpling Drop.
///
/// Warm, soft, and rounded. Every color comes from this palette so the
/// whole app reads as one cozy kitchen.
abstract final class DumplingTheme {
  // Backgrounds.
  static const cream = Color(0xFFFFF6E9);
  static const creamDark = Color(0xFFF7E8D0);
  static const bamboo = Color(0xFFD9A867);
  static const bambooDark = Color(0xFFB9854A);
  static const boardWell = Color(0xFFFBEFD9);

  // Ink for text.
  static const ink = Color(0xFF5B4636);
  static const inkSoft = Color(0xFF8A715C);

  // Accents.
  static const peach = Color(0xFFFFB48A);
  static const mint = Color(0xFFA8E6CF);
  static const sky = Color(0xFF9ED4F5);
  static const lemon = Color(0xFFFFE49C);
  static const pink = Color(0xFFFFC2D4);
  static const lilac = Color(0xFFCCB8F0);
  static const wasabi = Color(0xFFC5E08B);

  static const star = Color(0xFFFFC93C);

  /// One body color per dumpling filling (per piece kind).
  static const fillings = <Color>[
    sky, // po (I)
    lemon, // bao (O)
    pink, // mei (T)
    mint, // edamame (S)
    peach, // gyoza (Z)
    lilac, // ube (J)
    wasabi, // veggie (L)
  ];

  static TextStyle display({
    double size = 32,
    Color color = ink,
    double weight = 800,
  }) {
    return TextStyle(
      fontFamily: 'Baloo',
      fontSize: size,
      color: color,
      fontVariations: [FontVariation('wght', weight)],
      height: 1.1,
    );
  }

  static TextStyle body({
    double size = 16,
    Color color = ink,
    double weight = 600,
  }) {
    return TextStyle(
      fontFamily: 'Baloo',
      fontSize: size,
      color: color,
      fontVariations: [FontVariation('wght', weight)],
      height: 1.2,
    );
  }

  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      fontFamily: 'Baloo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: peach,
        surface: cream,
      ),
    );
  }
}
