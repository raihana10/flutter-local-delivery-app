class MockSuperAdminData {
  // KPI Stats
  static const Map<String, dynamic> dashboardStats = {
    'commandes_actives': 142,
    'revenus_jour': 15420.50,
    'livreurs_actifs': 45,
    'nouveaux_users': 12,
  };

  // Chart Data
  static const List<Map<String, dynamic>> weeklyRevenue = [
    {'day': 'Lun', 'revenue': 12000},
    {'day': 'Mar', 'revenue': 15000},
    {'day': 'Mer', 'revenue': 13500},
    {'day': 'Jeu', 'revenue': 17000},
    {'day': 'Ven', 'revenue': 22000},
    {'day': 'Sam', 'revenue': 25000},
    {'day': 'Dim', 'revenue': 19000},
  ];

  static const List<Map<String, dynamic>> ordersByStatus = [
    {'status': 'Confirmée', 'count': 45, 'color': 0xFFFFBA00}, // accent (jaune)
    {'status': 'Préparée', 'count': 30, 'color': 0xFFF57C00}, // orange
    {'status': 'En livraison', 'count': 67, 'color': 0xFF1976D2}, // bleu
    {'status': 'Livrée', 'count': 1200, 'color': 0xFF4CD964}, // vert
  ];

  // Mock Users
  static final List<Map<String, dynamic>> users = [
    {
      'id_user': 1,
      'nom': 'Ahmed Local',
      'email': 'ahmed@client.com',
      'role': 'client',
      'est_actif': true,
      'created_at': '2023-01-15T08:00:00Z',
    },
    {
      'id_user': 2,
      'nom': 'Youssef Livreur',
      'email': 'youssef@livreur.com',
      'role': 'livreur',
      'est_actif': true, // Changed to true to simulate active mission
      'documents_validation': true,
      'created_at': '2023-10-05T09:30:00Z',
      'courses_count': 145,
      'rating': 4.9,
    },
    {
      'id_user': 3,
      'nom': 'Pizza Tétouan',
      'email': 'contact@pizza-tetouan.ma',
      'role': 'business',
      'type_business': 'restaurant',
      'est_actif': true,
      'documents_validation': true,
      'is_open': true,
      'created_at': '2022-05-20T10:00:00Z',
      'revenue': 45200.0,
      'rating': 4.9,
    },
    {
      'id_user': 4,
      'nom': 'Driss Client',
      'email': 'driss@client.com',
      'role': 'client',
      'est_actif': true,
      'created_at': '2023-11-12T14:20:00Z',
    },
    {
      'id_user': 5,
      'nom': 'Pharmacie Centrale',
      'email': 'pharmacie@business.com',
      'role': 'business',
      'type_business': 'pharmacie',
      'est_actif': false,
      'documents_validation': false,
      'is_open': false,
      'created_at': '2023-12-01T11:00:00Z',
      'revenue': 0.0,
      'rating': 0.0,
    },
    {
      'id_user': 6,
      'nom': 'Ali Livreur',
      'email': 'ali@livreur.com',
      'role': 'livreur',
      'est_actif': true,
      'documents_validation': true,
      'created_at': '2023-11-20T14:00:00Z',
      'courses_count': 120,
      'rating': 4.8,
    },
    {
      'id_user': 7,
      'nom': 'Burger House',
      'email': 'contact@burger-house.ma',
      'role': 'business',
      'type_business': 'restaurant',
      'est_actif': true,
      'documents_validation': true,
      'is_open': true,
      'created_at': '2023-02-15T09:00:00Z',
      'revenue': 32100.0,
      'rating': 4.7,
    },
    {
      'id_user': 8,
      'nom': 'Karim Livreur',
      'email': 'karim@livreur.com',
      'role': 'livreur',
      'est_actif': false,
      'documents_validation': false,
      'created_at': '2023-12-06T10:00:00Z',
      'courses_count': 0,
      'rating': 0.0,
    },
  ];

  // Mock Orders
  static final List<Map<String, dynamic>> orders = [
    {
      'id_commande': 1001,
      'client': 'Ahmed Local',
      'livreur': 'Youssef Livreur',
      'business': 'Pizza Tétouan',
      'statut': 'en_livraison',
      'type': 'food_delivery',
      'prix_total': 150.00,
      'prix_donne': 150.00,
      'date': '2023-12-05T19:30:00Z',
      'is_blocked': false,
    },
    {
      'id_commande': 1002,
      'client': 'Driss Client',
      'livreur': null,
      'business': 'Pharmacie Centrale',
      'statut': 'confirmee',
      'type': 'shopping',
      'prix_total': 210.50,
      'prix_donne': 210.50,
      'date': '2023-12-05T20:15:00Z',
      'is_blocked': true,
      'blocked_since': '45 min'
    },
    {
      'id_commande': 1003,
      'client': 'Sara M',
      'livreur': 'Ali Livreur',
      'business': 'Burger House',
      'statut': 'livree',
      'type': 'food_delivery',
      'prix_total': 450.00,
      'prix_donne': 450.00,
      'date': '2023-12-05T14:00:00Z',
      'is_blocked': false,
    },
  ];

  // Promo Codes Data
  static final List<Map<String, dynamic>> promoCodes = [
    {
      'id': 1,
      'code': 'WELCOME50',
      'reduction': '50 MAD',
      'utilisation': 342,
      'valid_until': '2024-12-31T23:59:59Z',
      'est_actif': true,
    },
    {
      'id': 2,
      'code': 'SUMMER20',
      'reduction': '20%',
      'utilisation': 1560,
      'valid_until': '2023-08-31T23:59:59Z',
      'est_actif': false,
    },
    {
      'id': 3,
      'code': 'FREE_DELIVERY',
      'reduction': 'Livraison Gratuite',
      'utilisation': 890,
      'valid_until': '2024-06-30T23:59:59Z',
      'est_actif': true,
    }
  ];

  // Live Drivers Map Data
  static final List<Map<String, dynamic>> liveDrivers = [
    {
      'id_user': 2,
      'nom': 'Youssef Livreur',
      'lat': 35.5889,
      'lng': -5.3626, // Tétouan coordinates
      'status': 'en_mission'
    },
    {
      'id_user': 6,
      'nom': 'Ali Livreur',
      'lat': 35.5780,
      'lng': -5.3700,
      'status': 'disponible'
    }
  ];

  static final List<Map<String, dynamic>> notifications = [
    {
      'id': 1,
      'titre': 'Nouveau livreur en attente!',
      'message': 'Un nouveau livreur attend la validation de ses documents.',
      'type': 'alert',
      'date': 'Il y a 10 min'
    },
    {
      'id': 2,
      'titre': 'Commande bloquée',
      'message': 'La commande #1002 est confirmée depuis plus de 30 minutes.',
      'type': 'warning',
      'date': 'Il y a 1h'
    }
  ];
}
