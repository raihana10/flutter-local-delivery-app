class CommandeModel {
  final String id;
  final String restaurant;
  final String adresse;
  final double distance; // en km
  final double prix;     // en MAD
  final int tempsRestant; // en secondes (compte à rebours pour accepter)
  final double? latRestaurant;
  final double? lngRestaurant;
  final double? latClient;
  final double? lngClient;

  const CommandeModel({
    required this.id,
    required this.restaurant,
    required this.adresse,
    required this.distance,
    required this.prix,
    required this.tempsRestant,
    this.latRestaurant,
    this.lngRestaurant,
    this.latClient,
    this.lngClient,
  });

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id:             json['id'] as String,
      restaurant:     json['restaurant'] as String,
      adresse:        json['adresse'] as String,
      distance:       (json['distance'] as num).toDouble(),
      prix:           (json['prix'] as num).toDouble(),
      tempsRestant:   json['tempsRestant'] as int,
      latRestaurant:  json['latRestaurant'] != null ? (json['latRestaurant'] as num).toDouble() : null,
      lngRestaurant:  json['lngRestaurant'] != null ? (json['lngRestaurant'] as num).toDouble() : null,
      latClient:      json['latClient'] != null ? (json['latClient'] as num).toDouble() : null,
      lngClient:      json['lngClient'] != null ? (json['lngClient'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'restaurant':   restaurant,
    'adresse':      adresse,
    'distance':     distance,
    'prix':         prix,
    'tempsRestant': tempsRestant,
    'latRestaurant': latRestaurant,
    'lngRestaurant': lngRestaurant,
    'latClient':    latClient,
    'lngClient':    lngClient,
  };
}