import 'commande_model.dart';
import 'package:geolocator/geolocator.dart';

class CommandeSupabaseModel extends CommandeModel {
  final int idCommande;
  final int idClient;
  final int? idAdresse;
  final String statutCommande;
  final String typeCommande;
  final double prixTotal;
  final double fraisLivraisonDb;

  // Extra fields for UI display
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
    required this.fraisLivraisonDb,
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
    String? clientName,
  }) : super(
          id: id,
          restaurant: restaurant,
          adresse: adresse,
          distance: distance,
          prix: prix,
          fraisLivraison: fraisLivraisonDb,
          tempsRestant: tempsRestant,
          latRestaurant: latRestaurant,
          lngRestaurant: lngRestaurant,
          latClient: latClient,
          lngClient: lngClient,
          clientName: clientName,
        );

  factory CommandeSupabaseModel.fromJson(Map<String, dynamic> json, {double? driverLat, double? driverLng}) {
    final clientData = json['client'] as Map<String, dynamic>?;
    final userData = clientData?['app_user'] as Map<String, dynamic>?;
    final String phone = userData?['num_tl'] ?? '';
    final String cName = userData?['nom'] ?? 'Client Inconnu';

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
        
        String businessName = 'Inconnu';
        double? lat;
        double? lng;

        if (l['produit'] != null && l['produit']['business'] != null) {
          final b = l['produit']['business'];
          if (b['app_user'] != null) {
            businessName = b['app_user']['nom'] ?? 'Inconnu';
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
      fraisLivraisonDb: json['frais_livraison'] != null ? (json['frais_livraison'] as num).toDouble() : 0.0,
      numTlClient: phone,
      items: parsedItems,
      rawItems: rawItemsParsed,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,

      id: 'CMD-${json['id_commande']}',
      restaurant: firstBusiness,
      adresse: adresseData?['ville'] ?? 'Adresse inconnue',
      distance: computedDistance,
      prix: (json['prix_total'] as num).toDouble(),
      tempsRestant: 60,
      latRestaurant: latRestaurant ?? 35.5711, 
      lngRestaurant: lngRestaurant ?? -5.3694,
      latClient: latClient,
      lngClient: lngClient,
      clientName: cName,
    );
  }
}
