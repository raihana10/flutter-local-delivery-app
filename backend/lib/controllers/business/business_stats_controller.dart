import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class BusinessStatsController {
  Future<Response> getDashboardStats(Request request) async {
    try {
      final businessIdStr = request.headers['x-business-id'];
      if (businessIdStr == null) return Response(400, body: jsonEncode({'error': 'Missing Business ID'}));
      
      final userId = int.parse(businessIdStr);
      final business = await SupabaseConfig.client
          .from('business')
          .select('id_business')
          .eq('id_user', userId)
          .single();
      final businessId = business['id_business'] as int;

      // Fetch products for this business
      final productsRes = await SupabaseConfig.client
          .from('produit')
          .select('id_produit, nom_produit')
          .eq('id_business', businessId);
      final productIds = productsRes.map<int>((p) => p['id_produit'] as int).toList();

      if (productIds.isEmpty) {
        return Response.ok(jsonEncode({
          'revenus_totaux': 0,
          'total_commandes': 0,
          'top_produits': []
        }), headers: {'content-type': 'application/json'});
      }

      // Fetch order lines containing these products to calculate stats
      final orderLines = await SupabaseConfig.client
          .from('ligne_commande')
          .select('id_commande, quantite, total_ligne, nom_snapshot, id_produit, commande(created_at)')
          .filter('id_produit', 'in', productIds)
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

      return Response.ok(jsonEncode({
        'revenus_totaux': totalRevenu,
        'total_commandes': uniqueOrders.length,
        'top_produits': topProducts,
        'chart_data': chartData
      }), headers: {'content-type': 'application/json'});

    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }
}
