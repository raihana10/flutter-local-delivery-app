import 'package:flutter/material.dart';
import '../../data/datasources/business_api_service.dart';
import 'auth_provider.dart';

class BusinessDataProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final int? overrideBusinessId;
  late final BusinessApiService apiService;

  bool isLoading = false;
  Map<String, dynamic> stats = {};
  Map<String, dynamic> profile = {};
  List<dynamic> notifications = [];

  BusinessDataProvider({required this.authProvider, this.overrideBusinessId}) {
    apiService = BusinessApiService(authProvider, overrideBusinessId: overrideBusinessId);
    print('🔧 BusinessDataProvider created with overrideBusinessId: $overrideBusinessId');
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    stats = await apiService.getStats();
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    profile = await apiService.getProfile();
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final success = await apiService.updateProfile(data);
    if (success) {
      await fetchProfile();
    }
    return success;
  }

  Future<void> fetchNotifications() async {
    notifications = await apiService.getNotifications();
    notifyListeners();
  }

  int get unreadNotificationsCount {
    return notifications.where((n) => n['est_lu'] == false).length;
  }

  Future<void> markAsRead(String id) async {
    final success = await apiService.markNotificationAsRead(id);
    if (success) {
      await fetchNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final success = await apiService.markAllAsRead();
    if (success) {
      await fetchNotifications();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _setLoading(true);
    final success = await apiService.updateOrderStatus(orderId, status);
    if (success) {
      await fetchDashboardStats(); // Refresh stats/recent orders
    }
    _setLoading(false);
    return success;
  }

  Future<void> fetchAll() async {
    // ✅ Bypasser si admin mode
    if (overrideBusinessId == null && !authProvider.isAuthenticated) return;
    _setLoading(true);
    await Future.wait([
      fetchDashboardStats(),
      fetchProfile(),
      fetchNotifications(),
    ]);
    _setLoading(false);
  }
}
