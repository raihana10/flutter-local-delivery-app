import 'package:dio/dio.dart';
import '../../core/providers/auth_provider.dart';

class BusinessApiService {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8084');
  final Dio _dio = Dio();
  final AuthProvider authProvider;

  BusinessApiService(this.authProvider);

  Options _getAuthOptions() {
    final userId = authProvider.user?.id;
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
}
