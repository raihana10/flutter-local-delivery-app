import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales selon cahier des charges
  static const Color primary      = Color(0xFF0f1e3d);  // 220 60% 15% - Headers, navbar, boutons principaux, fond navigation
  static const Color secondary    = Color(0xFF507394);  // 215 30% 45% - Icônes, chips inactifs, textes secondaires
  static const Color accent       = Color(0xFFFFBA00);  // 37 100% 50% - CTAs, badges actifs, étoiles, indicateurs
  static const Color gold         = Color(0xFFBB8A52);  // 33 48% 53% - Prix, highlights, liens "Voir tout"

  // Fond
  static const Color background   = Color(0xFFF5F0E8);  // 36 33% 94% - Fond général off-white chaud
  static const Color card         = Color(0xFFFFFFFF);  // 0 0% 100% - Fond des cartes uniquement

  // Textes
  static const Color foreground   = Color(0xFF1A1A1A);  // 0 0% 10% - Texte principal corps
  static const Color mutedForeground = Color(0xFF737373); // 0 0% 45% - Texte grisé, labels secondaires

  // Status
  static const Color destructive  = Color(0xFFE53935);  // 0 84% 60% - Badges annulés, actions supprimer
  static const Color border       = Color(0xFFE5DFD4);  // 36 20% 88% - Bordures subtiles

  // Alias pour compatibilité avec code existant
  static const Color navyDark     = primary;
  static const Color navyMedium   = secondary;
  static const Color yellow       = accent;
  static const Color yellowLight  = accent;
  static const Color cardWhite    = card;
  static const Color textPrimary  = foreground;
  static const Color textSecondary = mutedForeground;
  static const Color textWhite    = Color(0xFFFFFFFF);
  static const Color online       = Color(0xFF4CD964);
  static const Color offline      = mutedForeground;
  static const Color red          = destructive;
  static const Color mapRoute     = accent;

  AppColors._();
}