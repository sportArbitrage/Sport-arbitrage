import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const primaryColor = Color(0xFF0055FF);
  static const secondaryColor = Color(0xFF00C853);
  static const accentColor = Color(0xFFFF6B00);
  
  static const errorColor = Color(0xFFE53935);
  static const warningColor = Color(0xFFFFC107);
  static const successColor = Color(0xFF43A047);
  
  static const darkBgColor = Color(0xFF121212);
  static const darkCardColor = Color(0xFF1E1E1E);
  static const darkDividerColor = Color(0xFF323232);
  
  static const lightBgColor = Color(0xFFF5F5F5);
  static const lightCardColor = Color(0xFFFFFFFF);
  static const lightDividerColor = Color(0xFFE0E0E0);
  
  // Text styles
  static TextStyle _getTextStyle(double size, FontWeight weight, Color color) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
  
  // Light theme text
  static TextStyle get lightHeadingStyle => _getTextStyle(24, FontWeight.bold, Colors.black);
  static TextStyle get lightSubheadingStyle => _getTextStyle(18, FontWeight.w600, Colors.black);
  static TextStyle get lightBodyStyle => _getTextStyle(16, FontWeight.normal, Colors.black87);
  static TextStyle get lightCaptionStyle => _getTextStyle(14, FontWeight.w300, Colors.black54);
  
  // Dark theme text
  static TextStyle get darkHeadingStyle => _getTextStyle(24, FontWeight.bold, Colors.white);
  static TextStyle get darkSubheadingStyle => _getTextStyle(18, FontWeight.w600, Colors.white);
  static TextStyle get darkBodyStyle => _getTextStyle(16, FontWeight.normal, Colors.white70);
  static TextStyle get darkCaptionStyle => _getTextStyle(14, FontWeight.w300, Colors.white54);
  
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: lightBgColor,
      surface: lightCardColor,
    ),
    scaffoldBackgroundColor: lightBgColor,
    appBarTheme: AppBarTheme(
      color: primaryColor,
      elevation: 0,
      titleTextStyle: _getTextStyle(20, FontWeight.w600, Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: lightCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: lightDividerColor,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: lightHeadingStyle,
      displayMedium: lightSubheadingStyle,
      bodyLarge: lightBodyStyle,
      bodySmall: lightCaptionStyle,
    ),
  );
  
  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: darkBgColor,
      surface: darkCardColor,
    ),
    scaffoldBackgroundColor: darkBgColor,
    appBarTheme: AppBarTheme(
      color: darkCardColor,
      elevation: 0,
      titleTextStyle: _getTextStyle(20, FontWeight.w600, Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: darkDividerColor,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: darkHeadingStyle,
      displayMedium: darkSubheadingStyle,
      bodyLarge: darkBodyStyle,
      bodySmall: darkCaptionStyle,
    ),
  );
} 