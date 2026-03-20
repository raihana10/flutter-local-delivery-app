class ApiConstants {
  // --- Mode développement ---
  // Mettre à false quand le backend est prêt
  static const bool useMockData = true;

  // --- Base URL ---
  // TODO: Remplacer par l'URL réelle du backend Node.js
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // 10.0.2.2 = localhost depuis émulateur Android

  // --- Endpoints Livreur ---
  static const String livreurStatus =
      '/livreur/status'; // PUT  → toggle En ligne/Hors ligne
  static const String livreurCommandes =
      '/livreur/commandes'; // GET  → commandes disponibles
  static const String acceptCommande = '/livreur/commandes/accept'; // POST
  static const String refuserCommande = '/livreur/commandes/refuse'; // POST
  static const String livreurGains = '/livreur/gains'; // GET  → stats gains
  static const String livreurProfil = '/livreur/profil'; // GET  → infos livreur

  // --- Timeouts ---
  static const int connectTimeout = 5000; // ms
  static const int receiveTimeout = 10000; // ms

  ApiConstants._();
}
