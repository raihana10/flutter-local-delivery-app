import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/business_api_service.dart';
import 'auth_provider.dart';

class BusinessDataProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  late final BusinessApiService apiService;

  bool isLoading = false;
  Map<String, dynamic> stats = {};
  Map<String, dynamic> profile = {};
  List<dynamic> notifications = [];

  final int? overrideBusinessId;

  /// Clé primaire `business.id_business` (table `produit.id_business`), résolue pour le commerce courant.
  /// En mode admin (`overrideBusinessId` = `id_user`), chargée via [loadIdBusinessPk].
  int? idBusinessPk;

  BusinessDataProvider({required this.authProvider, this.overrideBusinessId}) {
    apiService = BusinessApiService(authProvider, overrideBusinessId: overrideBusinessId);
  }

  /// À appeler au chargement de l’écran commerce : fournit le bon `id_business` même si l’admin n’est pas le business.
  Future<void> loadIdBusinessPk() async {
    try {
      if (overrideBusinessId != null) {
        final row = await Supabase.instance.client
            .from('business')
            .select('id_business')
            .eq('id_user', overrideBusinessId!)
            .maybeSingle();
        idBusinessPk = row?['id_business'] as int?;
      } else {
        idBusinessPk = authProvider.roleId;
      }
    } catch (e) {
      debugPrint('loadIdBusinessPk: $e');
      idBusinessPk = authProvider.roleId;
    }
    notifyListeners();
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
  // ✅ Bypasser si admin mode (overrideBusinessId fourni)
  if (overrideBusinessId == null && !authProvider.isAuthenticated) return;
  _setLoading(true);
  await Future.wait([
    fetchDashboardStats(),
    fetchProfile(),
    fetchNotifications(),
    fetchOrders(),
  ]);
  _setLoading(false);
}
  List<Map<String, dynamic>> orders = [];

 Future<void> fetchOrders() async {
  try {
    // ✅ Utiliser overrideBusinessId si disponible (admin mode)
    final userId = overrideBusinessId ?? authProvider.user?.id;
    if (userId == null) {
      orders = [];
      notifyListeners();
      return;
    }

    final supabase = Supabase.instance.client;

    // 1. Get business ID depuis id_user
    final business = await supabase
        .from('business')
        .select('id_business')
        .eq('id_user', userId)
        .maybeSingle();

    if (business == null) {
      orders = [];
      notifyListeners();
      return;
    }
    final businessId = business['id_business'] as int;
    print('📦 fetchOrders for businessId: $businessId (userId: $userId)');

    // 2. Get all products for this business
    final productsRes = await supabase
        .from('produit')
        .select('id_produit')
        .eq('id_business', businessId);

    final productIds = productsRes
        .map<int>((p) => p['id_produit'] as int)
        .toList();

    if (productIds.isEmpty) {
      orders = [];
      notifyListeners();
      return;
    }

    // 3. Get order lines that contain these products
    final orderLines = await supabase
        .from('ligne_commande')
        .select('id_commande, quantite, total_ligne, commande(*)')
        .inFilter('id_produit', productIds);

    // 4. Group by order id
    Map<int, Map<String, dynamic>> groupedOrders = {};
    for (var line in (orderLines as List)) {
      final cData = line['commande'];
      if (cData == null) continue;

      final cId = cData['id_commande'] as int;
      if (!groupedOrders.containsKey(cId)) {
        groupedOrders[cId] = {
          'id_commande': cId,
          'client_name': 'Client #${cData['id_client']}',
          'items': 0,
          'statut_commande': cData['statut_commande'],
          'created_at': cData['created_at'],
          'total': cData['prix_total'],
          'id_client': cData['id_client'],
        };
      }
      groupedOrders[cId]!['items'] += (line['quantite'] as num).toInt();
    }

    // 5. Convert to list and sort by date
    orders = groupedOrders.values.toList();
    orders.sort((a, b) => DateTime.parse(b['created_at'])
        .compareTo(DateTime.parse(a['created_at'])));

    print('✅ fetchOrders: ${orders.length} commandes trouvées');
  } catch (e) {
    debugPrint('❌ fetchOrders Error: $e');
    orders = [];
  }
  notifyListeners();
}
  Future<void> updateOrderStatus(int commandeId, String newStatus) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('commande')
          .update({'statut_commande': newStatus})
          .eq('id_commande', commandeId);
      await fetchOrders();
    } catch (e) {
      print('updateOrderStatus Error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchOrderDetails(int orderId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final orderResponse = await supabase
          .from('commande')
          .select('*, client(*, app_user(*)), adresse(*), timeline(*, livreur(*, app_user(*)))')
          .eq('id_commande', orderId)
          .maybeSingle();

      if (orderResponse == null) return null;

      final linesResponse = await supabase
          .from('ligne_commande')
          .select('*, produit(*)')
          .eq('id_commande', orderId);

      return {
        'order': orderResponse,
        'lines': linesResponse,
      };
    } catch (e) {
      print('fetchOrderDetails Error: $e');
      return null;
    }
  }
}
