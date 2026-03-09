import 'package:flutter/material.dart';

class AppColors {
  // Business App Specific Colors
  static const Color forest     = Color(0xFF0F1F3D); // hsl(220, 60%, 15%)
  static const Color forestLight = Color(0xFF1E2B4A); // hsl(220, 50%, 22%)
  static const Color amber      = Color(0xFFFFBB00); // hsl(44, 100%, 50%)
  static const Color sage       = Color(0xFF506D95); // hsl(215, 30%, 45%)
  static const Color gold       = Color(0xFFC18C4D); // hsl(33, 48%, 53%)
  static const Color warmWhite  = Color(0xFFF1EEE6); // hsl(36, 33%, 94%)
  static const Color nearBlack  = Color(0xFF1A1A1A); // hsl(0, 0%, 10%)
  
  // Couleurs principales (Legacy)
  static const Color navyDark    = Color(0xFF1A2340);  
  static const Color yellow      = Color(0xFFF5A623);  

  // Fond
  static const Color background  = Color(0xFFF1EEE6);  
  static const Color cardWhite   = Color(0xFFFFFFFF);  

  // Textes
  static const Color textPrimary   = Color(0xFF0F1F3D); 
  static const Color textSecondary = Color(0xFF8A94A6); 
  static const Color textWhite     = Color(0xFFFFFFFF);
  static const Color mutedForeground = Color(0xFF737373);

  // Status
  static const Color online  = Color(0xFF4CD964); 
  static const Color offline = Color(0xFF8A94A6); 
  static const Color red     = Color(0xFFFF3B30); 
  static const Color destructive = Color(0xFFDC2626); // Red-600

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1F0A193C),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x2E0A193C),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  AppColors._();
}