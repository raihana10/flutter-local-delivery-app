import 'dart:convert';

enum ProductType { meal, grocery, pharmacy }

class BusinessProduct {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category; // type_produit
  final bool isAvailable;
  final String? imageUrl;
  final String? brand;

  BusinessProduct({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.imageUrl,
    this.brand,
  });

  factory BusinessProduct.fromCsv(List<dynamic> row) {
    // Expecting: nom, description, prix, categorie, stock (unused for now as per schema)
    return BusinessProduct(
      name: row[0].toString(),
      description: row[1].toString(),
      price: double.tryParse(row[2].toString()) ?? 0.0,
      category: mapCategory(row[3].toString()),
      isAvailable: true,
    );
  }

  static String mapCategory(String cat) {
    cat = cat.toLowerCase();
    if (cat.contains('meal') || cat.contains('plat')) return 'meal';
    if (cat.contains('grocery') || cat.contains('epicerie')) return 'grocery';
    if (cat.contains('pharmacy') || cat.contains('pharmacie')) return 'pharmacy';
    return 'meal'; // Default
  }

  Map<String, dynamic> toJson() {
    return {
      'nom_produit': name,
      'description': description,
      'prix_vente': price,
      'type_produit': category,
      'est_dispo': isAvailable,
      'image': imageUrl,
    };
  }
}
