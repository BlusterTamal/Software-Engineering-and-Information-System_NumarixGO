/*
 * File: lib/app_themes.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/app_themes.dart
 * Description: Defines light and dark theme configurations for the app
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static final TextTheme _baseTextTheme = GoogleFonts.latoTextTheme(
    const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: const Color(0xFFF4F7FE),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
      background: const Color(0xFFF4F7FE),
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: const Color(0xFF16213E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      background: const Color(0xFF16213E),
      onBackground: Colors.white,
      surface: const Color(0xFF1E2A47),
      onSurface: Colors.white,
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}