import 'package:flutter/material.dart';

class AppTheme {

  static ThemeData mainTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFFF4F7F3),

    primaryColor: Color(0xFF2E7D32),

    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF66BB6A),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)
        ),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
      ),
    ),
  );
}