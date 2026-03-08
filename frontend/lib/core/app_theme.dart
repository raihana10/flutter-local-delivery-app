import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      primary:   AppColors.yellow,
      secondary: AppColors.navyDark,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor:    AppColors.navyDark,
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
      backgroundColor:      AppColors.navyDark,
      selectedItemColor:    AppColors.yellow,
      unselectedItemColor:  AppColors.textSecondary,
      elevation:            0,
      type:                 BottomNavigationBarType.fixed,
    ),

    // Cards
    cardTheme: CardThemeData(
      color:       AppColors.cardWhite,
      elevation:   2,
      shadowColor: Colors.black12,
      shape:       RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.textWhite,
        minimumSize:     const Size(double.infinity, 52),
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navyDark,
        minimumSize:     const Size(double.infinity, 52),
        side:            const BorderSide(color: AppColors.navyDark, width: 1.5),
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  AppTheme._();
}