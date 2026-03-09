import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.poppinsTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary:   AppColors.forest,
      secondary: AppColors.amber,
      surface: AppColors.cardWhite,
      error: AppColors.destructive,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor:    AppColors.forest,
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
      backgroundColor:      AppColors.forest,
      selectedItemColor:    AppColors.amber,
      unselectedItemColor:  AppColors.mutedForeground,
      elevation:            0,
      type:                 BottomNavigationBarType.fixed,
    ),

    // Cards
    cardTheme: CardThemeData(
      color:       AppColors.cardWhite,
      elevation:   0, // We use BoxShadow manually for "card-shadow"
      shape:       RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.amber,
        minimumSize:     const Size(double.infinity, 56),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        minimumSize:     const Size(double.infinity, 52),
        side:            const BorderSide(color: AppColors.gold, width: 1.5),
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  AppTheme._();
}