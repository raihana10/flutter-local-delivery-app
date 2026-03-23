class GainsModel {
  final double aujourdhui; // gains du jour en MAD
  final double semaine; // gains du jour en MAD
  final List<double> parJour; // [Lun, Mar, Mer, Jeu, Ven, Sam, Dim]
  final Map<String, int> repartitionType;
  final List<LivraisonRecente> livraisonsRecentes;
  final int totalLivraisons;
  final double totalDistance;

  const GainsModel({
    required this.aujourdhui,
    required this.semaine,
    required this.parJour,
    required this.repartitionType,
    required this.livraisonsRecentes,
    this.totalLivraisons = 0,
    this.totalDistance = 0.0,
  });

  factory GainsModel.fromJson(Map<String, dynamic> json) {
    return GainsModel(
      aujourdhui: (json['aujourdhui'] as num).toDouble(),
      semaine: (json['semaine'] as num).toDouble(),
      parJour:
          (json['parJour'] as List).map((e) => (e as num).toDouble()).toList(),
      repartitionType: Map<String, int>.from(json['repartitionType'] as Map),
      livraisonsRecentes: (json['livraisonsRecentes'] as List)
          .map((e) => LivraisonRecente.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LivraisonRecente {
  final String restaurant;
  final String heure; // ex: "14:30"
  final double montant; // en MAD

  const LivraisonRecente({
    required this.restaurant,
    required this.heure,
    required this.montant,
  });

  factory LivraisonRecente.fromJson(Map<String, dynamic> json) {
    return LivraisonRecente(
      restaurant: json['restaurant'] as String,
      heure: json['heure'] as String,
      montant: (json['montant'] as num).toDouble(),
    );
  }
}
