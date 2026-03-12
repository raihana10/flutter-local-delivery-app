import 'package:dio/dio.dart';
import '../../core/providers/auth_provider.dart';

class ClientApiService {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8084');
  final Dio _dio = Dio();
  final AuthProvider authProvider;

  ClientApiService(this.authProvider);

  Options _getAuthOptions() {
    final clientId = authProvider.user?.id;
    return Options(headers: {
      if (clientId != null) 'x-client-id': clientId.toString(),
      'Content-Type': 'application/json',
    });
  }

  // --- Profile & Addresses ---

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('$baseUrl/client/profile-address/profile', options: _getAuthOptions());
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      print('getProfile Error: $e');
      return {};
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('$baseUrl/client/profile-address/profile', data: data, options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
      print('updateProfile Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getAddresses() async {
    try {
      final response = await _dio.get('$baseUrl/client/profile-address/addresses', options: _getAuthOptions());
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      print('getAddresses Error: $e');
      return [];
    }
  }

  Future<bool> addAddress(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('$baseUrl/client/profile-address/addresses', data: data, options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
      print('addAddress Error: $e');
      return false;
    }
  }

  Future<bool> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('$baseUrl/client/profile-address/addresses/$id', data: data, options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
      print('updateAddress Error: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final response = await _dio.delete('$baseUrl/client/profile-address/addresses/$id', options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
      print('deleteAddress Error: $e');
      return false;
    }
  }

  // --- Businesses ---

  Future<List<dynamic>> getBusinesses(String type) async {
    try {
      final response = await _dio.get('$baseUrl/client/businesses?type=$type', options: _getAuthOptions());
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      print('getBusinesses Error for $type: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getBusinessDetails(String id) async {
    try {
      final response = await _dio.get('$baseUrl/client/businesses/$id', options: _getAuthOptions());
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
       print('getBusinessDetails Error: $e');
      return {};
    }
  }

  Future<List<dynamic>> getBusinessProducts(String id) async {
    try {
      final response = await _dio.get('$baseUrl/client/businesses/$id/products', options: _getAuthOptions());
      return response.data['data'] as List<dynamic>;
    } catch (e) {
       print('getBusinessProducts Error: $e');
      return [];
    }
  }

  // --- Orders ---

  Future<Map<String, dynamic>?> createOrder(Map<String, dynamic> checkoutData) async {
    try {
      final response = await _dio.post(
        '$baseUrl/client/orders', 
        data: checkoutData,
        options: _getAuthOptions()
      );
      if (response.data['success'] == true) {
         return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('createOrder Error: $e');
      return null;
    }
  }

  Future<List<dynamic>> getOrders() async {
    try {
      final response = await _dio.get('$baseUrl/client/orders', options: _getAuthOptions());
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      print('getOrders Error: $e');
      return [];
    }
  }

  // --- Notifications ---

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('$baseUrl/client/notifications', options: _getAuthOptions());
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      print('getNotifications Error: $e');
      return [];
    }
  }

  Future<bool> markNotificationAsRead(String notiId) async {
    try {
      final response = await _dio.patch('$baseUrl/client/notifications/$notiId/read', options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
       print('markNotificationAsRead Error: $e');
      return false;
    }
  }

  // --- Payment Methods ---

  Future<List<dynamic>> getPaymentMethods() async {
    try {
      final response = await _dio.get('$baseUrl/client/payment-methods', options: _getAuthOptions());
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      print('getPaymentMethods Error: $e');
      return [];
    }
  }

  Future<bool> addPaymentMethod(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('$baseUrl/client/payment-methods', data: data, options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
      print('addPaymentMethod Error: $e');
      return false;
    }
  }

  Future<bool> deletePaymentMethod(String id) async {
    try {
      final response = await _dio.delete('$baseUrl/client/payment-methods/$id', options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
      print('deletePaymentMethod Error: $e');
      return false;
    }
  }

  Future<bool> setDefaultPaymentMethod(String id) async {
    try {
      final response = await _dio.patch('$baseUrl/client/payment-methods/$id/default', options: _getAuthOptions());
      return response.data['success'] == true;
    } catch (e) {
      print('setDefaultPaymentMethod Error: $e');
      return false;
    }
  }
}
