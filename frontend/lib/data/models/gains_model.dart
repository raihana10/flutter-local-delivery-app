class GainsModel {
  final double aujourdhui; // gains du jour en MAD
  final double semaine; // gains de la semaine en MAD
  final List<double> parJour; // [Lun, Mar, Mer, Jeu, Ven, Sam, Dim]
  final List<LivraisonRecente> livraisonsRecentes;

  const GainsModel({
    required this.aujourdhui,
    required this.semaine,
    required this.parJour,
    required this.livraisonsRecentes,
  });

  factory GainsModel.fromJson(Map<String, dynamic> json) {
    return GainsModel(
      aujourdhui: (json['aujourdhui'] as num).toDouble(),
      semaine: (json['semaine'] as num).toDouble(),
      parJour:
          (json['parJour'] as List).map((e) => (e as num).toDouble()).toList(),
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
