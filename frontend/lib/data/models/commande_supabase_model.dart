import 'package:app/data/models/commande_model.dart';
import 'package:geolocator/geolocator.dart';

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
  final List<Map<String, dynamic>> rawItems;
  final DateTime? createdAt;

  CommandeSupabaseModel({
    required this.idCommande,
    required this.idClient,
    this.idAdresse,
    required this.statutCommande,
    required this.typeCommande,
    required this.prixTotal,
    required this.numTlClient,
    this.items = const [],
    this.rawItems = const [],
    this.createdAt,

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

  factory CommandeSupabaseModel.fromJson(Map<String, dynamic> json, {double? driverLat, double? driverLng}) {
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
    List<Map<String, dynamic>> rawItemsParsed = [];
    String firstBusiness = 'Restaurant (Inconnu)';
    double? latRestaurant;
    double? lngRestaurant;
    
    
    for (var l in lignesData) {
      if (l is Map<String, dynamic>) {
        final qte = l['quantite'] ?? 1;
        final nom = l['nom_snapshot'] ?? 'Produit';
        final prixUnitaire = l['prix_snapshot'] ?? 0.0;
        
        // Try to extra business from relational mapping 'produit' -> 'business' -> 'app_user'
        String businessName = 'Inconnu';
        double? lat;
        double? lng;

        if (l['produit'] != null && l['produit']['business'] != null) {
          final b = l['produit']['business'];
          if (b['app_user'] != null) {
            businessName = b['app_user']['nom'] ?? 'Inconnu';
            
            // Extract coordinates
            final uaMap = b['app_user']['user_adresse'];
            if (uaMap is List && uaMap.isNotEmpty) {
               final adr = uaMap.first['adresse'];
               if (adr != null) {
                 lat = (adr['latitude'] as num?)?.toDouble();
                 lng = (adr['longitude'] as num?)?.toDouble();
               }
            } else if (uaMap is Map && uaMap['adresse'] != null) {
               lat = (uaMap['adresse']['latitude'] as num?)?.toDouble();
               lng = (uaMap['adresse']['longitude'] as num?)?.toDouble();
            }
          }
        } else if (l['business_snapshot'] != null) {
          businessName = l['business_snapshot'];
        }
        
        if (firstBusiness == 'Restaurant (Inconnu)' && businessName != 'Inconnu') {
          firstBusiness = businessName;
        }

        if (lat != null && latRestaurant == null) latRestaurant = lat;
        if (lng != null && lngRestaurant == null) lngRestaurant = lng;

        parsedItems.add('${qte}x $nom');
        rawItemsParsed.add({
          'quantite': qte,
          'nom': nom,
          'prix': (prixUnitaire as num).toDouble(),
          'business': businessName,
        });
      }
    }
    
    double computedDistance = 2.5;
    if (driverLat != null && driverLng != null && latRestaurant != null && lngRestaurant != null) {
      computedDistance = Geolocator.distanceBetween(driverLat, driverLng, latRestaurant!, lngRestaurant!) / 1000.0;
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
      rawItems: rawItemsParsed,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,

      // Mapping to old UI fields for compatibility
      id: 'CMD-${json['id_commande']}',
      restaurant: firstBusiness,
      adresse: adresseData?['ville'] ?? 'Adresse inconnue',
      distance: computedDistance,
      prix: (json['prix_total'] as num).toDouble(),
      tempsRestant: 60,
      latRestaurant: latRestaurant ?? 35.5711, // Fallback if missing
      lngRestaurant: lngRestaurant ?? -5.3694,
      latClient: latClient,
      lngClient: lngClient,
    );
  }
}
