import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary:   AppColors.primary,
      secondary: AppColors.secondary,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor:    AppColors.primary,
      foregroundColor:    AppColors.textWhite,
      elevation:          0,
      centerTitle:        false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.light,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.primary,
      selectedItemColor:    AppColors.accent,
      unselectedItemColor:  AppColors.secondary,
      elevation:            0,
      type:                 BottomNavigationBarType.fixed,
    ),

    // Cards
    cardTheme: CardThemeData(
      color:       AppColors.card,
      elevation:   2,
      shadowColor: Colors.black12,
      shape:       RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
        minimumSize:     const Size(double.infinity, 56),
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize:     const Size(double.infinity, 56),
        side:            const BorderSide(color: AppColors.primary, width: 1.5),
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  AppTheme._();
}