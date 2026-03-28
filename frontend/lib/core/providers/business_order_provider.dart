import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

class BusinessOrderProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final int? overrideBusinessId;

  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;

  BusinessOrderProvider({required this.authProvider, this.overrideBusinessId});

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    try {
      final userId = overrideBusinessId ?? authProvider.user?.id;
      if (userId == null) {
        orders = [];
        notifyListeners();
        return;
      }

      final supabase = Supabase.instance.client;

      // 1. Get business ID from user ID
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

      // 2. Get all product IDs for this business
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

      // 3. Get order lines containing these products
      final orderLines = await supabase
          .from('ligne_commande')
          .select('id_commande, quantite, total_ligne, commande(*)')
          .inFilter('id_produit', productIds);

      // 4. Group by order ID
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

    } catch (e) {
      debugPrint('❌ BusinessOrderProvider fetchOrders Error: $e');
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
      debugPrint('❌ BusinessOrderProvider updateOrderStatus Error: $e');
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
      debugPrint('❌ BusinessOrderProvider fetchOrderDetails Error: $e');
      return null;
    }
  }
}
