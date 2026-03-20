import 'package:app/data/models/commande_model.dart';

class CommandeSupabaseModel extends CommandeModel {
  final int idCommande;
  final int idClient;
  final int? idAdresse;
  final String statutCommande;
  final String typeCommande;
  final double prixTotal;

  // Extra fields for UI display that we will fetch via Joins or use mock for now
  // since the DB might not have all the restaurant info directly inside `commande`
  final String numTlClient;
  final List<String> items;

  CommandeSupabaseModel({
    required this.idCommande,
    required this.idClient,
    this.idAdresse,
    required this.statutCommande,
    required this.typeCommande,
    required this.prixTotal,
    required this.numTlClient,
    this.items = const [],

    // Parent fields
    required String id,
    required String restaurant,
    required String adresse,
    required double distance,
    required double prix,
    required int tempsRestant,
    double? latRestaurant,
    double? lngRestaurant,
    double? latClient,
    double? lngClient,
  }) : super(
          id: id,
          restaurant: restaurant,
          adresse: adresse,
          distance: distance,
          prix: prix,
          tempsRestant: tempsRestant,
          latRestaurant: latRestaurant,
          lngRestaurant: lngRestaurant,
          latClient: latClient,
          lngClient: lngClient,
        );

  factory CommandeSupabaseModel.fromJson(Map<String, dynamic> json) {
    // We expect the JSON to be a result of a join, looking somewhat like:
    // {
    //   'id_commande': 1,
    //   '...': '...',
    //   'ligne_commande': [ { 'quantite': 2, 'nom_snapshot': 'Burger' } ]
    // }

    final clientData = json['client'] as Map<String, dynamic>?;
    final userData = clientData?['app_user'] as Map<String, dynamic>?;
    final String phone = userData?['num_tl'] ?? '';

    final adresseData = json['adresse'] as Map<String, dynamic>?;
    final double? latClient = adresseData != null
        ? (adresseData['latitude'] as num?)?.toDouble()
        : null;
    final double? lngClient = adresseData != null
        ? (adresseData['longitude'] as num?)?.toDouble()
        : null;

    final lignesData = json['ligne_commande'] as List<dynamic>? ?? [];
    List<String> parsedItems = [];
    for (var l in lignesData) {
      if (l is Map<String, dynamic>) {
        final qte = l['quantite'] ?? 1;
        final nom = l['nom_snapshot'] ?? 'Produit';
        parsedItems.add('${qte}x $nom');
      }
    }

    return CommandeSupabaseModel(
      idCommande: json['id_commande'] as int,
      idClient: json['id_client'] as int,
      idAdresse: json['id_adresse'] as int?,
      statutCommande: json['statut_commande'] as String,
      typeCommande: json['type_commande'] as String,
      prixTotal: (json['prix_total'] as num).toDouble(),
      numTlClient: phone,
      items: parsedItems,

      // Mapping to old UI fields for compatibility
      id: 'CMD-${json['id_commande']}',
      restaurant:
          'Restaurant (Supabase)', // Temporary until we join with lignes_commande -> produit -> business
      adresse: adresseData?['ville'] ?? 'Adresse inconnue',
      distance: 2.5, // Mocked for now unless we calculate it
      prix: (json['prix_total'] as num).toDouble(),
      tempsRestant: 60,
      latRestaurant: 35.5711, // Mocked Tétouan center
      lngRestaurant: -5.3694,
      latClient: latClient,
      lngClient: lngClient,
    );
  }
}
