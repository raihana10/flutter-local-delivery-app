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
      // Mettre à jour l'API service avec l'ID business résolu
      apiService.setResolvedBusinessId(idBusinessPk);
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
    try {
      final businessId = idBusinessPk;
      if (businessId == null) {
        stats = {};
        notifyListeners();
        return;
      }

      // Fetch products for this business
      final productsRes = await Supabase.instance.client
          .from('produit')
          .select('id_produit, nom_produit')
          .eq('id_business', businessId)
          .isFilter('deleted_at', null);

      final productIds = productsRes.map<int>((p) => p['id_produit'] as int).toList();

      if (productIds.isEmpty) {
        stats = {
          'revenus_totaux': 0,
          'nb_commandes': 0,
          'note_moyenne': '0.0',
          'top_produits': [],
          'chart_data': List.filled(7, 0.0),
          'recent_orders': []
        };
        notifyListeners();
        return;
      }

      // Fetch order lines containing these products
      final orderLines = await Supabase.instance.client
          .from('ligne_commande')
          .select('id_commande, quantite, total_ligne, nom_snapshot, id_produit, commande(created_at)')
          .inFilter('id_produit', productIds)
          .isFilter('deleted_at', null);

      double totalRevenu = 0;
      Set<int> uniqueOrders = {};
      Map<int, Map<String, dynamic>> productStats = {};
      
      List<double> chartData = List.filled(7, 0.0);
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);

      for (var line in orderLines) {
        final prixLigne = (line['total_ligne'] as num).toDouble();
        final qty = line['quantite'] as int;
        final pId = line['id_produit'] as int;
        final pName = line['nom_snapshot'] as String;

        totalRevenu += prixLigne;
        uniqueOrders.add(line['id_commande'] as int);

        if (!productStats.containsKey(pId)) {
          productStats[pId] = {'nom': pName, 'qte': 0, 'revenu': 0.0};
        }
        productStats[pId]!['qte'] += qty;
        productStats[pId]!['revenu'] += prixLigne;
        
        final commandeData = line['commande'];
        if (commandeData != null && commandeData is Map) {
          final createdAtStr = commandeData['created_at'];
          if (createdAtStr != null) {
            final date = DateTime.tryParse(createdAtStr.toString());
            if (date != null) {
              final dateDay = DateTime(date.year, date.month, date.day);
              final diff = todayDay.difference(dateDay).inDays;
              if (diff >= 0 && diff < 7) {
                chartData[6 - diff] += prixLigne;
              }
            }
          }
        }
      }

      // Sort Top Products by quantity
      var topProducts = productStats.values.toList();
      topProducts.sort((a, b) => (b['qte'] as int).compareTo(a['qte'] as int));
      topProducts = topProducts.take(5).toList();

      // Fetch recent orders (5 most recent)
      List<Map<String, dynamic>> recentOrders = [];
      if (uniqueOrders.isNotEmpty) {
        final orderIds = uniqueOrders.toList();
        final recentOrdersData = await Supabase.instance.client
            .from('commande')
            .select('''
              id_commande,
              statut_commande,
              prix_total,
              created_at,
              client(
                id_client,
                app_user:id_user(nom, num_tl)
              )
            ''')
            .inFilter('id_commande', orderIds)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false)
            .limit(5);

        recentOrders = recentOrdersData.map((order) {
          final client = order['client'];
          final clientUser = client is Map ? client['app_user'] : null;
          return {
            'id_commande': order['id_commande'],
            'statut_commande': order['statut_commande'],
            'prix_total': order['prix_total'],
            'created_at': order['created_at'],
            'client_nom': clientUser?['nom'] ?? 'Client',
            'client_tel': clientUser?['num_tl'] ?? '',
          };
        }).toList();
      }

      stats = {
        'revenus_totaux': totalRevenu,
        'nb_commandes': uniqueOrders.length,
        'note_moyenne': '4.5', // Placeholder
        'top_produits': topProducts,
        'chart_data': chartData,
        'recent_orders': recentOrders
      };
      notifyListeners();
    } catch (e) {
      debugPrint('fetchDashboardStats Error: $e');
      stats = {};
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    try {
      final businessId = idBusinessPk;
      if (businessId == null) {
        profile = {};
        notifyListeners();
        return;
      }

      final businessData = await Supabase.instance.client
          .from('business')
          .select('*, app_user(*)')
          .eq('id_business', businessId)
          .maybeSingle();

      if (businessData != null) {
        profile = businessData;
      } else {
        profile = {};
      }
      notifyListeners();
    } catch (e) {
      debugPrint('fetchProfile Error: $e');
      profile = {};
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final businessId = idBusinessPk;
      if (businessId == null) return false;
      await Supabase.instance.client
          .from('business')
          .update(data)
          .eq('id_business', businessId);
      await fetchProfile();
      return true;
    } catch (e) {
      debugPrint('updateProfile Error: $e');
      return false;
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final businessId = idBusinessPk;
      if (businessId == null) {
        notifications = [];
        notifyListeners();
        return;
      }

      final notificationsData = await Supabase.instance.client
          .from('notification')
          .select('*')
          .eq('id_business', businessId)
          .order('created_at', ascending: false);

      notifications = notificationsData;
      notifyListeners();
    } catch (e) {
      debugPrint('fetchNotifications Error: $e');
      notifications = [];
      notifyListeners();
    }
  }

  int get unreadNotificationsCount {
    return notifications.where((n) => n['est_lu'] == false).length;
  }

  Future<void> markAsRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notification')
          .update({'est_lu': true})
          .eq('id_notification', id);
      await fetchNotifications();
    } catch (e) {
      debugPrint('markAsRead Error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final businessId = idBusinessPk;
      if (businessId == null) return;
      await Supabase.instance.client
          .from('notification')
          .update({'est_lu': true})
          .eq('id_business', businessId);
      await fetchNotifications();
    } catch (e) {
      debugPrint('markAllAsRead Error: $e');
    }
  }


  Future<void> fetchAll() async {
    // Bypasser si admin mode
    if (overrideBusinessId == null && !authProvider.isAuthenticated) return;
    _setLoading(true);
    await Future.wait([
      fetchDashboardStats(),
      fetchProfile(),
      fetchNotifications(),
    ]);
    _setLoading(false);
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _setLoading(true);
    try {
      final intId = int.tryParse(orderId);
      if (intId == null) {
        _setLoading(false);
        return false;
      }

      await Supabase.instance.client
          .from('commande')
          .update({'statut_commande': status})
          .eq('id_commande', intId);
      
      await fetchDashboardStats();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('updateOrderStatus Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchOrderDetails(dynamic orderId) async {
    try {
      final supabase = Supabase.instance.client;
      final intId = int.tryParse(orderId.toString());
      if (intId == null) return null;
      
      final orderResponse = await supabase
          .from('commande')
          .select('*, client(*, app_user(*)), adresse(*), timeline(*, livreur(*, app_user(*)))')
          .eq('id_commande', intId)
          .maybeSingle();

      if (orderResponse == null) return null;

      final linesResponse = await supabase
          .from('ligne_commande')
          .select('*, produit(*)')
          .eq('id_commande', intId);

      return {
        'order': orderResponse,
        'lines': linesResponse,
      };
    } catch (e) {
      debugPrint('❌ BusinessDataProvider fetchOrderDetails Error: $e');
      return null;
    }
  }
}
