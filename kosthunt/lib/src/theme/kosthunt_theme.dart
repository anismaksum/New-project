import 'package:flutter/material.dart';

class KostHuntTheme {
  static const Color ink = Color(0xFF171816);
  static const Color muted = Color(0xFF6F746C);
  static const Color paper = Color(0xFFF7F5EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sage = Color(0xFF687462);
  static const Color teal = Color(0xFF0E5F58);
  static const Color amber = Color(0xFFA97842);
  static const Color line = Color(0xFFE0DDD4);
  static const Color softSage = Color(0xFFE7ECE3);

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ink,
      scaffoldBackgroundColor: paper,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: ink,
        secondary: teal,
        surface: surface,
        error: Color(0xFF9B332C),
        onPrimary: surface,
        onSecondary: surface,
        onSurface: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: line),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: softSage,
        disabledColor: line,
        labelStyle: KostText.label,
        secondaryLabelStyle: KostText.label.copyWith(color: ink),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: surface,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: KostText.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: KostText.label,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: ink,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: line,
    );
  }
}

class KostText {
  static const TextStyle display = TextStyle(
    color: KostHuntTheme.ink,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    height: 1.04,
  );

  static const TextStyle headingLarge = TextStyle(
    color: KostHuntTheme.ink,
    fontSize: 29,
    fontWeight: FontWeight.w600,
    height: 1.14,
  );

  static const TextStyle heading = TextStyle(
    color: KostHuntTheme.ink,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    color: KostHuntTheme.ink,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle titleSmall = TextStyle(
    color: KostHuntTheme.ink,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    color: KostHuntTheme.ink,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle muted = TextStyle(
    color: KostHuntTheme.muted,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    color: KostHuntTheme.ink,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
}
