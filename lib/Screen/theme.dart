import 'package:flutter/material.dart';

class appTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6B43FF),
    scaffoldBackgroundColor: const Color(0xFFEEEEEE),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6B43FF),
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.grey[300],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(color: Colors.black),
      bodySmall: TextStyle(color: Color.fromARGB(255, 81, 81, 81)),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF444444)),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6B43FF),
    scaffoldBackgroundColor: const Color(0xFF222222),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6B43FF),
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.grey[850],

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF6B43FF)),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF6B43FF)),
  );
}
