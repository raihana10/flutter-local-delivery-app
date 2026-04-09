import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/client_api_service.dart';
import 'auth_provider.dart';

class ClientDataProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  late final ClientApiService apiService;

  ClientDataProvider({required this.authProvider}) {
    apiService = ClientApiService(authProvider);
    _loadPaymentPreference();
  }

  bool isLoading = false;

  // Data Holders
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> pharmacies = [];
  List<Map<String, dynamic>> superMarkets = [];
  
  String? _activeCity;
  
  String get currentCity {
    if (_activeCity != null) return _activeCity!;
    if (addresses.isNotEmpty) {
      final def = addresses.firstWhere((a) => a['is_default'] == true, orElse: () => addresses.first);
      return def['adresse']?['ville'] ?? 'Tétouan';
    }
    return 'Tétouan';
  }

  void setActiveCity(String city) {
    _activeCity = city;
    notifyListeners();
  }

  List<Map<String, dynamic>> _filterByCity(List<Map<String, dynamic>> list) {
    final city = currentCity.toLowerCase().trim();
    if (city.isEmpty) return list;
    
    return list.where((b) {
      final appUser = b['app_user'] ?? {};
      final userAddresses = appUser['user_adresse'] as List<dynamic>? ?? [];
      if (userAddresses.isEmpty) return true; // Show businesses with no address
      
      for (var ua in userAddresses) {
        final adr = ua['adresse'] ?? {};
        final v = (adr['ville'] ?? '').toString().toLowerCase().trim();
        if (v == city) return true;
      }
      return false;
    }).toList();
  }

  List<Map<String, dynamic>> get filteredRestaurants => _filterByCity(restaurants);
  List<Map<String, dynamic>> get filteredPharmacies => _filterByCity(pharmacies);
  List<Map<String, dynamic>> get filteredSuperMarkets => _filterByCity(superMarkets);
  
  List<Map<String, dynamic>> get allRestaurants => restaurants;
  List<Map<String, dynamic>> get allPharmacies => pharmacies;
  List<Map<String, dynamic>> get allSuperMarkets => superMarkets;
  
  double deliveryFeeRate = 1.5;
  
  Map<String, dynamic>? profile;
  List<dynamic> addresses = [];
  List<dynamic> orders = [];
  List<dynamic> notifications = [];
  List<dynamic> paymentMethods = [];

  String? _preferredPaymentMethod;
  String get preferredPaymentMethod => _preferredPaymentMethod ?? 'cash';

  Future<void> _loadPaymentPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredPaymentMethod = prefs.getString('preferred_payment_method') ?? 'cash';
    notifyListeners();
  }
  List<dynamic> favorites = [];

  // Cart Data
  List<Map<String, dynamic>> cartItems = [];

  // Tracks the business whose products are in the cart (used for distance calculation)
  Map<String, dynamic>? _currentCartBusiness;

  void setCurrentBusiness(Map<String, dynamic>? business) {
    _currentCartBusiness = business;
    notifyListeners();
  }

  bool get isCurrentBusinessOpen {
    return _currentCartBusiness?['is_open'] == true;
  }


  /// Returns the primary address map {latitude, longitude} of the business in the cart, or null.
  Map<String, dynamic>? get businessAddress {
    final appUser = _currentCartBusiness?['app_user'] ?? {};
    final userAddresses = appUser['user_adresse'] as List<dynamic>? ?? [];
    if (userAddresses.isEmpty) return null;
    final primary = userAddresses.firstWhere(
      (ua) => ua['is_default'] == true,
      orElse: () => userAddresses.first,
    );
    return primary['adresse'] as Map<String, dynamic>?;
  }


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
      fetchFavorites(),
      _fetchAppConfigs()
    ]);
    _setLoading(false);
  }

  Future<void> _fetchRestaurants() async {
    final res = await apiService.getBusinesses('restaurant');
    restaurants = res.whereType<Map<String, dynamic>>().toList();
    notifyListeners();
  }

  Future<void> _fetchPharmacies() async {
    final res = await apiService.getBusinesses('pharmacie');
    pharmacies = res.whereType<Map<String, dynamic>>().toList();
    notifyListeners();
  }

  Future<void> _fetchSuperMarkets() async {
    final res = await apiService.getBusinesses('super-marche');
    superMarkets = res.whereType<Map<String, dynamic>>().toList();
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

  int get unreadNotificationsCount {
    return notifications.where((n) => n['est_lu'] == false).length;
  }

  Future<void> _fetchAppConfigs() async {
    try {
      final supabase = Supabase.instance.client;
      final config = await supabase
          .from('app_config')
          .select('valeur')
          .eq('cle', 'prix_par_km')
          .maybeSingle();
      if (config != null && config['valeur'] != null) {
        deliveryFeeRate = double.tryParse(config['valeur'].toString()) ?? 1.5;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching app_config: $e');
    }
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
    if (id == 'cash') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_payment_method', 'cash');
      _preferredPaymentMethod = 'cash';
      notifyListeners();
      return true;
    }

    final success = await apiService.setDefaultPaymentMethod(id);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_payment_method', 'card');
      _preferredPaymentMethod = 'card';
      await fetchPaymentMethods();
    }
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

  bool isFavoriteBusiness(String id) => isFavorite(int.tryParse(id) ?? 0);

  Future<void> toggleFavorite(dynamic idBusiness) async {
    final idStr = idBusiness.toString();
    final idInt = int.tryParse(idStr) ?? 0;
    
    if (isFavorite(idInt)) {
      final success = await apiService.removeFavorite(idInt);
      if (success) {
        favorites.removeWhere((f) => f['id_business'].toString() == idStr);
        notifyListeners();
      }
    } else {
      final success = await apiService.addFavorite(idInt);
      if (success) {
        await fetchFavorites(); // re-fetch to get full object map
      }
    }
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }
  Future<Map<String, dynamic>?> createOrderSupabase(Map<String, dynamic> checkoutData) async {
    try {
      final supabase = Supabase.instance.client;
      final clientId = authProvider.roleId;
      if (clientId == null) return null;

      final cartItems = checkoutData['items'] as List<dynamic>;
      // Get business ID from checkout data or from first cart item
      final businessId = checkoutData['id_business'] ?? cartItems.first['id_business'];
      
      if (businessId == null) {
        print('createOrderSupabase Error: businessId is null');
        return null;
      }

      final commandeData = {
        'id_client': clientId,
        'id_business': int.parse(businessId.toString()),
        'id_adresse': checkoutData['id_adresse'],
        'statut_commande': 'confirmee', // Direct confirmation for now to match user expectation
        'type_commande': checkoutData['type_commande'] ?? 'food_delivery',
        'prix_total': cartItems.fold(0.0, (sum, item) => sum + (double.parse(item['prix_snapshot'].toString()) * (item['quantite'] as int))),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase.from('commande').insert(commandeData).select().single();
      final orderId = response['id_commande'];

      // 2. Create Ligne Commande
      final lines = cartItems.map((item) => {
        'id_commande': orderId,
        'id_produit': int.parse(item['id_produit'].toString()),
        'quantite': item['quantite'],
        'prix_snapshot': item['prix_snapshot'],
        'nom_snapshot': item['nom_snapshot'],
      }).toList();

      await supabase.from('ligne_commande').insert(lines);

      return response;
    } catch (e) {
      print('createOrderSupabase Error: $e');
      return null;
    }
  }
}
