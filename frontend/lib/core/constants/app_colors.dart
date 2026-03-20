import 'package:flutter/material.dart';

class AppColors {
  // ── COULEURS PRINCIPALES (Selon cahier des charges) ──────────────────
  static const Color primary = Color(
      0xFF0f1e3d); // 220 60% 15% - Headers, navbar, boutons principaux, fond navigation
  static const Color secondary = Color(
      0xFF507394); // 215 30% 45% - Icônes, chips inactifs, textes secondaires
  static const Color accent = Color(
      0xFFFFBA00); // 37 100% 50% - CTAs, badges actifs, étoiles, indicateurs
  static const Color gold =
      Color(0xFFBB8A52); // 33 48% 53% - Prix, highlights, liens "Voir tout"

  // Aliases pour Business App (Compatibilité)
  static const Color forest = primary;
  static const Color amber = accent;
  static const Color sage = secondary;
  static const Color forestLight = Color(0xFF1E2B4A);
  static const Color warmWhite = Color(0xFFF5F0E8);
  static const Color nearBlack = Color(0xFF1A1A1A);

  // Fond et Surfaces
  static const Color background =
      Color(0xFFF5F0E8); // 36 33% 94% - Fond général off-white chaud
  static const Color card =
      Color(0xFFFFFFFF); // 0 0% 100% - Fond des cartes uniquement
  static const Color cardWhite = card;

  // Textes et Contenus
  static const Color foreground =
      Color(0xFF1A1A1A); // 0 0% 10% - Texte principal corps
  static const Color textPrimary = foreground;
  static const Color mutedForeground =
      Color(0xFF737373); // 0 0% 45% - Texte grisé, labels secondaires
  static const Color textSecondary = mutedForeground;
  static const Color textWhite = Color(0xFFFFFFFF);

  // Statuts et Actions
  static const Color online = Color(0xFF4CD964);
  static const Color offline = mutedForeground;
  static const Color red = Color(0xFFE53935);
  static const Color destructive =
      Color(0xFFE53935); // 0 84% 60% - Badges annulés, actions supprimer
  static const Color mapRoute = accent;
  static const Color border = Color(0xFFE5DFD4);

  // Aliases Legacy
  static const Color navyDark = primary;
  static const Color navyMedium = secondary;
  static const Color yellow = accent;
  static const Color yellowLight = accent;

  // Ombres (Shadows)
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
