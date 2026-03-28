import 'package:dio/dio.dart';
import '../../core/providers/auth_provider.dart';

class BusinessApiService {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8084');
  final Dio _dio = Dio();
  final AuthProvider authProvider;
  final int? overrideBusinessId;

  BusinessApiService(this.authProvider, {this.overrideBusinessId});

  Options _getAuthOptions() {
    // We use the app_user ID (which is authProvider.user?.id) or override
    final userId = overrideBusinessId ?? authProvider.user?.id;
    return Options(headers: {
      if (userId != null) 'x-business-id': userId.toString(),
      'Content-Type': 'application/json',
    });
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _dio.get('$baseUrl/business/stats/dashboard', options: _getAuthOptions());
      return res.data;
    } catch (e) {
      print('getStats Error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _dio.get('$baseUrl/business/profile', options: _getAuthOptions());
      return res.data;
    } catch (e) {
      print('getProfile Error: $e');
      return {};
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.patch('$baseUrl/business/profile', data: data, options: _getAuthOptions());
      return true;
    } catch (e) {
      print('updateProfile Error: $e');
      return false;
    }
  }

  Future<bool> addAddress(Map<String, dynamic> data) async {
    try {
      await _dio.post('$baseUrl/business/profile/addresses', data: data, options: _getAuthOptions());
      return true;
    } catch (e) {
      print('addAddress Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getAddresses() async {
    try {
      final res = await _dio.get('$baseUrl/business/profile/addresses', options: _getAuthOptions());
      return res.data['data'] as List<dynamic>;
    } catch (e) {
      print('getAddresses Error: $e');
      return [];
    }
  }

  Future<bool> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('$baseUrl/business/profile/addresses/$id', data: data, options: _getAuthOptions());
      return true;
    } catch (e) {
      print('updateAddress Error: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      await _dio.delete('$baseUrl/business/profile/addresses/$id', options: _getAuthOptions());
      return true;
    } catch (e) {
      print('deleteAddress Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final res = await _dio.get('$baseUrl/business/notifications', options: _getAuthOptions());
      return res.data['data'] as List<dynamic>;
    } catch (e) {
      print('getNotifications Error: $e');
      return [];
    }
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      await _dio.patch('$baseUrl/business/notifications/$id/read', options: _getAuthOptions());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _dio.patch('$baseUrl/business/notifications/mark-all-read', options: _getAuthOptions());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final businessId = overrideBusinessId ?? authProvider.user?.id;
      if (businessId == null) return false;
      
      final response = await _dio.patch(
        '$baseUrl/business/$businessId/commandes/$orderId/statut',
        data: {'statut': status},
        options: _getAuthOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('updateOrderStatus Error: $e');
      return false;
    }
  }
}
