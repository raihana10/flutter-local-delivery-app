import '../models/commande_model.dart';
import '../models/gains_model.dart';

/// Données fictives pour le développement frontend
/// À remplacer par de vrais appels API quand le backend sera prêt
class LivreurMockDatasource {
  // --- Commande disponible ---
  static CommandeModel get mockCommande => const CommandeModel(
        id: 'CMD-001',
        restaurant: 'Café Atlas',
        adresse: '12, Rue Moulay Ismail',
        distance: 1.2,
        prix: 35,
        tempsRestant: 45,
        latRestaurant: 35.5711, // Coordonnées Tétouan
        lngRestaurant: -5.3694,
        latClient: 35.5750,
        lngClient: -5.3720,
      );

  // --- Gains ---
  static GainsModel get mockGains => GainsModel(
        aujourdhui: 245,
        semaine: 1340,
        parJour: [110, 85, 175, 150, 270, 320, 165], // Lun → Dim
        livraisonsRecentes: [
          const LivraisonRecente(
              restaurant: 'Dar Zitoun', heure: '14:30', montant: 35),
          const LivraisonRecente(
              restaurant: 'Café Atlas', heure: '12:15', montant: 25),
          const LivraisonRecente(
              restaurant: 'Snack El Medina', heure: '10:45', montant: 20),
          const LivraisonRecente(
              restaurant: 'Pizza Roma', heure: '09:00', montant: 30),
        ],
      );

  // --- Profil livreur ---
  static Map<String, dynamic> get mockProfil => {
        'id': 'LIV-001',
        'nom': 'Mohammed',
        'avatar': null, // URL image ou null
        'note': 4.8,
        'totalLivraisons': 142,
      };

  // --- Simuler un délai réseau (200ms) ---
  static Future<T> withDelay<T>(T data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return data;
  }
}
