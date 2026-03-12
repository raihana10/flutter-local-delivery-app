import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminApiService {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8084');
  final Dio _dio = Dio();

  Future<Options> _getAuthOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('x-admin-id');
    return Options(headers: {
      if (adminId != null) 'x-admin-id': adminId.toString(),
      'Content-Type': 'application/json',
    });
  }

  // Dashboard APIs
  Future<Map<String, dynamic>> getKPIs() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/dashboard/kpis', options: options);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getAlerts() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/dashboard/alerts', options: options);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'pending_validations': [], 'blocked_orders': []};
    }
  }

  Future<List<dynamic>> getLiveDrivers() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/dashboard/live-drivers', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getChartData() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/dashboard/chart', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // Users Management APIs
  Future<List<dynamic>> getClients() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/users/clients', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getLivreurs() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/users/livreurs', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getBusinesses() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/users/businesses', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(String idUser) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.patch('$baseUrl/admin/users/$idUser/toggle', options: options);
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> validateUser(String idUser) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.patch('$baseUrl/admin/users/$idUser/validate', options: options);
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Commandes Management APIs
  Future<List<dynamic>> getCommandes() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/commandes', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getCommandeDetail(String idCommande) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/commandes/$idCommande', options: options);
      return response.data['data'];
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Paiements Management APIs
  Future<List<dynamic>> getPaiements() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/paiements', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // Stats APIs
  Future<Map<String, dynamic>> getRevenus() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/stats/revenus', options: options);
      return response.data;
    } catch (e) {
      return {};
    }
  }

  // Notifications APIs
  Future<List<dynamic>> getNotifications() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/notifications', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}
