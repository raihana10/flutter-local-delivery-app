
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
  final Map<String, dynamic>? openingHours;
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
    return Business(
      id: json['id_business'] ?? 0,
      idUser: json['id_user'] ?? 0,
      type: BusinessType.fromString(json['type_business'] ?? 'restaurant'),
      description: json['description'],
      pdp: json['pdp'],
      openingHours: json['opening_hours'],
      tempsPreparation: json['temps_preparation'],
      isOpen: json['is_open'] ?? false,
      estActif: json['est_actif'] ?? false,
      user: json['app_user'] != null ? User.fromJson(json['app_user']) : null,
    );
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
  final Business? business;

  Produit({
    required this.id,
    required this.idBusiness,
    required this.nom,
    this.description,
    this.image,
    required this.type,
    required this.prix,
    this.createdAt,
    this.business,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id_produit'] ?? 0,
      idBusiness: json['id_business'] ?? 0,
      nom: json['nom_produit'] ?? '',
      description: json['description'],
      image: json['image'],
      type: json['type_produit'] ?? 'meal',
      prix: (json['prix_unitaire'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      business: json['business'] != null ? Business.fromJson(json['business']) : null,
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
    };
  }
}
