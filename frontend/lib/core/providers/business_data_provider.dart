import 'package:flutter/material.dart';
import '../../data/datasources/business_api_service.dart';
import 'auth_provider.dart';

class BusinessDataProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  late final BusinessApiService apiService;

  bool isLoading = false;
  Map<String, dynamic> stats = {};
  Map<String, dynamic> profile = {};
  List<dynamic> notifications = [];

  BusinessDataProvider({required this.authProvider}) {
    apiService = BusinessApiService(authProvider);
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

  Future<void> fetchAll() async {
    if (!authProvider.isAuthenticated) return;
    _setLoading(true);
    await Future.wait([
      fetchDashboardStats(),
      fetchProfile(),
      fetchNotifications(),
    ]);
    _setLoading(false);
  }
}
