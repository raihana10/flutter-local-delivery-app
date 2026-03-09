import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart';

class AppTheme {

  // ── LIGHT THEME ───────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor:   AppColors.yellow,
      primary:     AppColors.yellow,
      secondary:   AppColors.navyDark,
      brightness:  Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor:    AppColors.navyDark,
      foregroundColor:    AppColors.textWhite,
      elevation:          0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.navyDark,
      selectedItemColor:   AppColors.yellow,
      unselectedItemColor: AppColors.textSecondary,
      type:                BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color:     AppColors.cardWhite,
      elevation: 2,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // ── DARK THEME ────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1626), // fond très sombre
    colorScheme: ColorScheme.fromSeed(
      seedColor:  AppColors.yellow,
      primary:    AppColors.yellow,
      secondary:  AppColors.navyDark,
      brightness: Brightness.dark,
      surface:    const Color(0xFF1A2340),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor:    Color(0xFF0F1626),
      foregroundColor:    AppColors.textWhite,
      elevation:          0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     Color(0xFF0F1626),
      selectedItemColor:   AppColors.yellow,
      unselectedItemColor: Color(0xFF4A5568),
      type:                BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color:     const Color(0xFF1A2340),
      elevation: 0,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  AppTheme._();
}