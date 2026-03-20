import 'package:flutter/material.dart';
import '../../data/datasources/client_api_service.dart';
import 'auth_provider.dart';

class ClientDataProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  late final ClientApiService apiService;

  ClientDataProvider({required this.authProvider}) {
    apiService = ClientApiService(authProvider);
  }

  bool isLoading = false;

  // Data Holders
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> pharmacies = [];
  List<Map<String, dynamic>> superMarkets = [];

  Map<String, dynamic>? profile;
  List<dynamic> addresses = [];
  List<dynamic> orders = [];
  List<dynamic> notifications = [];
  List<dynamic> paymentMethods = [];
  List<dynamic> favorites = [];

  // Cart Data
  List<Map<String, dynamic>> cartItems = [];

  void addToCart(Map<String, dynamic> item) {
    cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> item) {
    cartItems.remove(item);
    notifyListeners();
  }

  void updateCartItem(int index, Map<String, dynamic> newItem) {
    if (index >= 0 && index < cartItems.length) {
      cartItems[index] = newItem;
      notifyListeners();
    }
  }

  void clearCart() {
    cartItems.clear();
    notifyListeners();
  }

  double get cartSubtotal {
    return cartItems.fold(0, (sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final quantity = item['quantity'] as int? ?? 1;
      return sum + (price * quantity);
    });
  }

  // Used for details
  final Map<String, Map<String, dynamic>> _businessDetailsCache = {};
  final Map<String, List<dynamic>> _businessProductsCache = {};

  Future<void> fetchHomeData() async {
    if (!authProvider.isAuthenticated) return;

    _setLoading(true);
    await Future.wait([
      _fetchRestaurants(),
      _fetchPharmacies(),
      _fetchSuperMarkets(),
      fetchProfile(),
      fetchAddresses(),
      fetchNotifications(),
      fetchPaymentMethods(),
      fetchFavorites()
    ]);
    _setLoading(false);
  }

  Future<void> _fetchRestaurants() async {
    final res = await apiService.getBusinesses('restaurant');
    restaurants = res.map((e) => e as Map<String, dynamic>).toList();
    notifyListeners();
  }

  Future<void> _fetchPharmacies() async {
    final res = await apiService.getBusinesses('pharmacie');
    pharmacies = res.map((e) => e as Map<String, dynamic>).toList();
    notifyListeners();
  }

  Future<void> _fetchSuperMarkets() async {
    final res = await apiService.getBusinesses('super-marche');
    superMarkets = res.map((e) => e as Map<String, dynamic>).toList();
    notifyListeners();
  }

  // Exposed fetchers
  Future<void> fetchProfile() async {
    profile = await apiService.getProfile();
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final success = await apiService.updateProfile(data);
    if (success) await fetchProfile();
    return success;
  }

  Future<void> fetchAddresses() async {
    addresses = await apiService.getAddresses();
    notifyListeners();
  }

  Future<bool> addAddress(Map<String, dynamic> data) async {
    final success = await apiService.addAddress(data);
    if (success) await fetchAddresses();
    return success;
  }

  Future<bool> updateAddress(String id, Map<String, dynamic> data) async {
    final success = await apiService.updateAddress(id, data);
    if (success) await fetchAddresses();
    return success;
  }

  Future<bool> deleteAddress(String id) async {
    final success = await apiService.deleteAddress(id);
    if (success) await fetchAddresses();
    return success;
  }

  Future<void> fetchOrders() async {
    orders = await apiService.getOrders();
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    notifications = await apiService.getNotifications();
    notifyListeners();
  }

  Future<void> fetchPaymentMethods() async {
    paymentMethods = await apiService.getPaymentMethods();
    notifyListeners();
  }

  Future<bool> addPaymentMethodCard(Map<String, dynamic> data) async {
    final success = await apiService.addPaymentMethod(data);
    if (success) await fetchPaymentMethods();
    return success;
  }

  Future<bool> deletePaymentMethod(String id) async {
    final success = await apiService.deletePaymentMethod(id);
    if (success) await fetchPaymentMethods();
    return success;
  }

  Future<bool> setDefaultPaymentMethod(String id) async {
    final success = await apiService.setDefaultPaymentMethod(id);
    if (success) await fetchPaymentMethods();
    return success;
  }

  // Detail fetchers
  Future<Map<String, dynamic>> getBusinessDetails(String id) async {
    if (_businessDetailsCache.containsKey(id)) {
      return _businessDetailsCache[id]!;
    }
    final doc = await apiService.getBusinessDetails(id);
    _businessDetailsCache[id] = doc;
    return doc;
  }

  Future<List<dynamic>> getBusinessProducts(String id) async {
    if (_businessProductsCache.containsKey(id)) {
      return _businessProductsCache[id]!;
    }
    final products = await apiService.getBusinessProducts(id);
    _businessProductsCache[id] = products;
    return products;
  }

  Future<List<dynamic>> getBusinessReviews(String id) async {
    return await apiService.getBusinessReviews(id);
  }

  Future<bool> addBusinessReview(String id, int rating, String comment) async {
    return await apiService.addBusinessReview(id, rating, comment);
  }

  // --- Favorites ---

  Future<void> fetchFavorites() async {
    favorites = await apiService.getFavorites();
    notifyListeners();
  }

  bool isFavorite(int idBusiness) {
    return favorites.any((f) => f['id_business'].toString() == idBusiness.toString());
  }

  Future<void> toggleFavorite(int idBusiness) async {
    if (isFavorite(idBusiness)) {
      final success = await apiService.removeFavorite(idBusiness);
      if (success) {
        favorites.removeWhere((f) => f['id_business'].toString() == idBusiness.toString());
        notifyListeners();
      }
    } else {
      final success = await apiService.addFavorite(idBusiness);
      if (success) {
        await fetchFavorites(); // re-fetch to get full object map
      }
    }
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }
}
