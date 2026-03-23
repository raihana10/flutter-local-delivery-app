class CommandeModel {
  final String id;
  final String restaurant;
  final String adresse;
  final double distance; // en km
  final double prix; // en MAD
  final double fraisLivraison; // en MAD
  final int tempsRestant; // en secondes (compte à rebours pour accepter)
  final double? latRestaurant;
  final double? lngRestaurant;
  final double? latClient;
  final double? lngClient;
  final String? clientName;

  const CommandeModel({
    required this.id,
    required this.restaurant,
    required this.adresse,
    required this.distance,
    required this.prix,
    this.fraisLivraison = 0.0,
    required this.tempsRestant,
    this.latRestaurant,
    this.lngRestaurant,
    this.latClient,
    this.lngClient,
    this.clientName,
  });

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id: json['id'] as String,
      restaurant: json['restaurant'] as String,
      adresse: json['adresse'] as String,
      distance: (json['distance'] as num).toDouble(),
      prix: (json['prix'] as num).toDouble(),
      fraisLivraison: json['fraisLivraison'] != null ? (json['fraisLivraison'] as num).toDouble() : 0.0,
      tempsRestant: json['tempsRestant'] as int,
      latRestaurant: json['latRestaurant'] != null
          ? (json['latRestaurant'] as num).toDouble()
          : null,
      lngRestaurant: json['lngRestaurant'] != null
          ? (json['lngRestaurant'] as num).toDouble()
          : null,
      latClient: json['latClient'] != null
          ? (json['latClient'] as num).toDouble()
          : null,
      lngClient: json['lngClient'] != null
          ? (json['lngClient'] as num).toDouble()
          : null,
      clientName: json['clientName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurant': restaurant,
        'adresse': adresse,
        'distance': distance,
        'prix': prix,
        'fraisLivraison': fraisLivraison,
        'tempsRestant': tempsRestant,
        'latRestaurant': latRestaurant,
        'lngRestaurant': lngRestaurant,
        'latClient': latClient,
        'lngClient': lngClient,
        'clientName': clientName,
      };
}
