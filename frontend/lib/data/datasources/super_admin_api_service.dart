import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminApiService {
  /// Préfère `API_URL` dans `frontend/.env`, sinon `--dart-define=API_URL=...`.
  static String get baseUrl {
    final u = dotenv.env['API_URL'];
    if (u != null && u.trim().isNotEmpty) return u.trim();
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8084',
    );
  }

  final Dio _dio = Dio();

  Future<Options> _getAuthOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('x-admin-id') ?? 1;
    return Options(headers: {
      'x-admin-id': adminId.toString(),
      'Content-Type': 'application/json',
    });
  }

  // Dashboard APIs
  Future<Map<String, dynamic>> getKPIs() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/dashboard/kpis', options: options);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getAlerts() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/dashboard/alerts', options: options);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'pending_validations': [], 'blocked_orders': []};
    }
  }

  Future<List<dynamic>> getLiveDrivers() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/dashboard/livreurs/positions',
          options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getChartData() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/dashboard/chart', options: options);
      return response.data as Map<String, dynamic> ;
    } catch (e) {
      print('❌ getChartData ERROR: $e');
      return {'weeklyRevenue': [], 'ordersByStatus': []};
    }
  }

  // Users Management APIs
  Future<List<dynamic>> getClients() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/users/clients', options: options);
      final body = response.data;
      if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is List) return decoded;
        return (decoded['data'] as List<dynamic>? ?? []);
      }
      if (body is List) return body;
      return (body['data'] as List<dynamic>? ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getLivreurs() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/users/livreurs', options: options);
      final body = response.data;
      if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is List) return decoded;
        return (decoded['data'] as List<dynamic>? ?? []);
      }
      if (body is List) return body;
      return (body['data'] as List<dynamic>? ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getBusinesses() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/users/businesses', options: options);
      final body = response.data;
      if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is List) return decoded;
        return (decoded['data'] as List<dynamic>? ?? []);
      }
      if (body is List) return body;
      return (body['data'] as List<dynamic>? ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(String idUser) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.patch('$baseUrl/admin/users/$idUser/toggle',
          options: options);
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> validateUser(String idUser) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.patch('$baseUrl/admin/users/$idUser/validate',
          options: options);
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Commandes Management APIs
  Future<List<dynamic>> getCommandes() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/commandes', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getCommandeDetail(String idCommande) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/commandes/$idCommande',
          options: options);
      return response.data['data'];
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Paiements Management APIs
  Future<List<dynamic>> getPaiements() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/paiements', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // Stats APIs
  Future<Map<String, dynamic>> getRevenus() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/stats/revenus', options: options);
      return response.data;
    } catch (e) {
      print('❌ getRevenus ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getLivreurStats() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/stats/livreurs', options: options);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ getLivreurStats ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getAllBusinessStats() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/stats/businesses', options: options);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ getAllBusinessStats ERROR: $e');
      return {};
    }
  }

  // Notifications APIs
  Future<List<dynamic>> getNotifications() async {
    try {
      final options = await _getAuthOptions();
      final response =
          await _dio.get('$baseUrl/admin/notifications', options: options);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendNotification(Map<String, dynamic> notificationData) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '$baseUrl/admin/notifications',
        data: notificationData,
        options: options,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ sendNotification ERROR: $e');
      return false;
    }
  }

  // ── Business Management ─────────────────────────────────
  Future<List<dynamic>> getAdminBusinesses() async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.get('$baseUrl/admin/business', options: options);
      return res.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getBusinessDetail(int id) async {
    try {
      final options = await _getAuthOptions();
      final res =
          await _dio.get('$baseUrl/admin/business/$id', options: options);
      return res.data['data'];
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Catalogue ────────────────────────────────
  Future<List<dynamic>> getBusinessProduits(int id) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.get('$baseUrl/admin/business/$id/produits',
          options: options);
      return res.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addProduit(
      int id, Map<String, dynamic> data) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.post('$baseUrl/admin/business/$id/produits',
          data: data, options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProduit(
      int id, int pid, Map<String, dynamic> data) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.patch('$baseUrl/admin/business/$id/produits/$pid',
          data: data, options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduit(int id, int pid) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.delete('$baseUrl/admin/business/$id/produits/$pid',
          options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> importProduitsCsv(
      int id, String csvContent) async {
    try {
      final options = await _getAuthOptions();
      final customOptions = Options(
        headers: {
          ...options.headers ?? {},
          'Content-Type': 'text/plain',
        },
      );
      final res = await _dio.post('$baseUrl/admin/business/$id/produits/import',
          data: csvContent, options: customOptions);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Commandes ────────────────────────────────
  Future<List<dynamic>> getBusinessCommandes(int id) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.get('$baseUrl/admin/business/$id/commandes',
          options: options);
      return res.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateCommandeStatut(
      int id, int cid, String statut) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.patch(
          '$baseUrl/admin/business/$id/commandes/$cid/statut',
          data: {'statut': statut},
          options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Heures ───────────────────────────────────
  Future<Map<String, dynamic>> updateBusinessHours(
      int id, Map<String, dynamic> hours) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.patch('$baseUrl/admin/business/$id/hours',
          data: hours, options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Promotions ───────────────────────────────
  Future<List<dynamic>> getBusinessPromotions(int id) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.get('$baseUrl/admin/business/$id/promotions',
          options: options);
      return res.data['data'] as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createPromotion(
      int id, Map<String, dynamic> data) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.post('$baseUrl/admin/business/$id/promotions',
          data: data, options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePromotion(int id, int pid) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.delete(
          '$baseUrl/admin/business/$id/promotions/$pid',
          options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Stats ────────────────────────────────────
  Future<Map<String, dynamic>> getBusinessStats(int id) async {
    try {
      final options = await _getAuthOptions();
      final res =
          await _dio.get('$baseUrl/admin/business/$id/stats', options: options);
      return res.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Commissions ──────────────────────────────
  Future<Map<String, dynamic>> getCommissions() async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.get('$baseUrl/admin/paiements/commissions',
          options: options);
      return res.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getLivreurGains(int id) async {
    try {
      final options = await _getAuthOptions();
      final res = await _dio.get('$baseUrl/admin/paiements/livreurs/$id',
          options: options);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Configurations APIs
  Future<Map<String, String>> getConfigs() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('$baseUrl/admin/config', options: options);
      final data = response.data['data'] as Map<String, dynamic>;
      
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('❌ getConfigs ERROR: $e');
      return {};
    }
  }

  Future<bool> updateConfig(String key, String value) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '$baseUrl/admin/config',
        data: {
          'cle': key,
          'valeur': value,
        },
        options: options,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ updateConfig ERROR: $e');
      return false;
    }
  }
}
