import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color navyDark    = Color(0xFF1A2340);  // Header, bottom nav
  static const Color navyMedium  = Color(0xFF1E2B4A);  // Cards sombres
  static const Color yellow      = Color(0xFFF5A623);  // Bouton En ligne, accents
  static const Color yellowLight = Color(0xFFFFC107);  // Hover / variante

  // Fond
  static const Color background  = Color(0xFFF2F2F7);  // Fond général gris clair
  static const Color cardWhite   = Color(0xFFFFFFFF);  // Cards blanches stats

  // Textes
  static const Color textPrimary   = Color(0xFF1A2340); // Titres
  static const Color textSecondary = Color(0xFF8A94A6); // Sous-titres, labels
  static const Color textWhite     = Color(0xFFFFFFFF);

  // Status
  static const Color online  = Color(0xFF4CD964); // Vert — En ligne
  static const Color offline = Color(0xFF8A94A6); // Gris — Hors ligne
  static const Color red     = Color(0xFFFF3B30); // Refuser / erreur

  // Carte
  static const Color mapRoute = Color(0xFFF5A623); // Tracé pointillé jaune

  AppColors._();
}