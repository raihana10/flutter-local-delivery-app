import 'dart:convert';
import 'package:app/data/models/auth_models.dart';

enum BusinessType {
  restaurant('restaurant'),
  superMarche('super-marche'),
  pharmacie('pharmacie');

  const BusinessType(this.value);
  final String value;

  static BusinessType fromString(String value) {
    return BusinessType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BusinessType.restaurant,
    );
  }
}

class Business {
  final int id;
  final int idUser;
  final BusinessType type;
  final String? description;
  final String? pdp;
  final dynamic openingHours;
  final int? tempsPreparation;
  final bool isOpen;
  final bool estActif;
  final User? user; // Joined from app_user

  Business({
    required this.id,
    required this.idUser,
    required this.type,
    this.description,
    this.pdp,
    this.openingHours,
    this.tempsPreparation,
    this.isOpen = false,
    this.estActif = false,
    this.user,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    dynamic parseOpeningHours(dynamic value) {
      if (value == null) return null;
      if (value is Map || value is List) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return jsonDecode(value);
        } catch (e) {
          return value; // Keep as string if parsing fails
        }
      }
      return value;
    }

    try {
      return Business(
        id: safeInt(json['id_business']),
        idUser: safeInt(json['id_user']),
        type: BusinessType.fromString(json['type_business'] ?? 'restaurant'),
        description: json['description']?.toString(),
        pdp: json['pdp']?.toString(),
        openingHours: parseOpeningHours(json['opening_hours']),
        tempsPreparation: json['temps_preparation'] is int 
            ? json['temps_preparation'] 
            : (json['temps_preparation'] != null ? int.tryParse(json['temps_preparation'].toString()) : null),
        isOpen: json['is_open'] == true || json['is_open'] == 1 || json['is_open']?.toString() == 'true',
        estActif: json['est_actif'] == true || json['est_actif'] == 1 || json['est_actif']?.toString() == 'true',
        user: json['app_user'] is Map<String, dynamic> 
            ? User.fromJson(json['app_user']) 
            : (json['app_user'] is List && (json['app_user'] as List).isNotEmpty
                ? User.fromJson((json['app_user'] as List).first)
                : null),
      );
    } catch (e) {
      print('DEBUG: Error parsing Business: $e');
      // Fallback object to avoid crashing the whole list
      return Business(
        id: safeInt(json['id_business']),
        idUser: safeInt(json['id_user']),
        type: BusinessType.restaurant,
        description: 'Error parsing business data',
      );
    }
  }
}

class Produit {
  final int id;
  final int idBusiness;
  final String nom;
  final String? description;
  final String? image;
  final String type; // meal, grocery, pharmacy
  final double prix;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final Business? business;

  bool get isAvailable => deletedAt == null;

  Produit({
    required this.id,
    required this.idBusiness,
    required this.nom,
    this.description,
    this.image,
    required this.type,
    required this.prix,
    this.createdAt,
    this.deletedAt,
    this.business,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }
    return Produit(
      id: safeInt(json['id_produit']),
      idBusiness: safeInt(json['id_business']),
      nom: (json['nom_produit'] ?? '').toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      type: (json['type_produit'] ?? 'meal').toString(),
      prix: double.tryParse((json['prix_unitaire'] ?? 0.0).toString()) ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'].toString()) : null,
      business: json['business'] is Map<String, dynamic> ? Business.fromJson(json['business']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id_produit': id,
      'id_business': idBusiness,
      'nom_produit': nom,
      'description': description,
      'image': image,
      'type_produit': type,
      'prix_unitaire': prix,
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }
}
class Promotion {
  final int id;
  final int idProduit;
  final double pourcentage;
  final DateTime dateDebut;
  final DateTime dateFin;
  final Produit? produit;

  Promotion({
    required this.id,
    required this.idProduit,
    required this.pourcentage,
    required this.dateDebut,
    required this.dateFin,
    this.produit,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }
    return Promotion(
      id: safeInt(json['id_promotion']),
      idProduit: safeInt(json['id_produit']),
      pourcentage: double.tryParse((json['pourcentage'] ?? 0.0).toString()) ?? 0.0,
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'].toString())
          : DateTime.now(),
      dateFin: json['date_fin'] != null
          ? DateTime.parse(json['date_fin'].toString())
          : DateTime.now().add(const Duration(days: 7)),
      produit: json['produit'] is Map<String, dynamic> ? Produit.fromJson(json['produit']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id_produit': idProduit,
      'pourcentage': pourcentage,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin.toIso8601String(),
    };
    if (id != 0) {
      data['id_promotion'] = id;
    }
    return data;
  }
}
