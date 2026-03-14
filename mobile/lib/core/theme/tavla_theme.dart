import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TavlaTheme {
  // Colors
  static const Color brown = Color(0xFF8B4513);
  static const Color darkBrown = Color(0xFF2C1810);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color gold = Color(0xFFD4A76A);
  static const Color boardDark = Color(0xFF5C3317);
  static const Color boardLight = Color(0xFFD2B48C);
  static const Color pointDark = Color(0xFF4A2A0A);
  static const Color pointLight = Color(0xFFE8D0B0);
  static const Color whitePiece = Color(0xFFFFFAF0);
  static const Color blackPiece = Color(0xFF1A1A1A);
  static const Color success = Color(0xFF28A745);
  static const Color danger = Color(0xFFDC3545);

  // Premium board colors (walnut + charcoal)
  static const Color boardFrame = Color(0xFF3A2414);
  static const Color boardFrameLight = Color(0xFF4A3020);
  static const Color boardFrameDark = Color(0xFF2A1A0E);
  static const Color surfaceGray = Color(0xFF3E3E40);
  static const Color surfaceGrayLight = Color(0xFF484848);
  static const Color pointRed = Color(0xFF1E1E20);
  static const Color pointRedLight = Color(0xFF2A2A2E);
  static const Color pointCream = Color(0xFFC0B5A5);
  static const Color pointCreamDark = Color(0xFFA89C8C);
  static const Color feltGreen = Color(0xFF3E3E40);
  static const Color feltGreenLight = Color(0xFF484848);
  static const Color barWood = Color(0xFF2E2E30);
  static const Color barWoodLight = Color(0xFF3C3C3E);
  static const Color pieceRim = Color(0xFF9A9A9C);
  static const Color pieceRimDark = Color(0xFF707072);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brown,
        brightness: Brightness.light,
        primary: brown,
        secondary: gold,
        surface: cream,
      ),
      scaffoldBackgroundColor: cream,
      textTheme: GoogleFonts.notoSerifTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBrown,
        foregroundColor: cream,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brown,
          side: const BorderSide(color: brown),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: brown.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brown, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brown,
        brightness: Brightness.dark,
        primary: gold,
        secondary: brown,
      ),
      scaffoldBackgroundColor: darkBrown,
      textTheme: GoogleFonts.notoSerifTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A0F08),
        foregroundColor: cream,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
