import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class BusinessStatsController {
  Future<Response> getDashboardStats(Request request) async {
    try {
      final businessIdStr = request.headers['x-business-id'];
      print('🔍 BusinessStatsController: x-business-id = $businessIdStr');

      if (businessIdStr == null) {
        return Response(400, body: jsonEncode({'error': 'Missing Business ID'}));
      }

      // ✅ x-business-id = id_user → récupérer id_business d'abord
      final userId = int.parse(businessIdStr);
      final businessRes = await SupabaseConfig.client
          .from('business')
          .select('id_business')
          .eq('id_user', userId)
          .single();
      final businessId = businessRes['id_business'] as int;
      print('🔍 BusinessStatsController: businessId = $businessId');

      // Produits du business
      final productsRes = await SupabaseConfig.client
          .from('produit')
          .select('id_produit, nom_produit')
          .eq('id_business', businessId)
          .isFilter('deleted_at', null);

      print('🔍 BusinessStatsController: produits trouvés = ${productsRes.length}');
      final productIds = productsRes.map<int>((p) => p['id_produit'] as int).toList();

      if (productIds.isEmpty) {
        print('🔍 BusinessStatsController: Aucun produit pour business $businessId');
        return Response.ok(
          jsonEncode({
            'revenus_totaux': 0,
            'nb_commandes': 0,
            'note_moyenne': '0.0',
            'nb_produits': 0,
            'top_produits': [],
            'chart_data': List.filled(7, 0.0),
            'recent_orders': [],
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Lignes de commande pour ces produits
      final orderLines = await SupabaseConfig.client
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

      // Top 5 produits
      var topProducts = productStats.values.toList();
      topProducts.sort((a, b) => (b['qte'] as int).compareTo(a['qte'] as int));
      topProducts = topProducts.take(5).toList();

      // Commandes récentes
      List<Map<String, dynamic>> recentOrders = [];
      if (uniqueOrders.isNotEmpty) {
        final orderIds = uniqueOrders.toList();
        final recentOrdersData = await SupabaseConfig.client
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

      // ✅ Note moyenne depuis store_review
      double noteMoyenne = 0.0;
      final reviews = await SupabaseConfig.client
          .from('store_review')
          .select('evaluation')
          .eq('id_business', businessId)
          .isFilter('deleted_at', null);

      if (reviews.isNotEmpty) {
        noteMoyenne = reviews.fold<double>(
                0.0, (sum, r) => sum + (r['evaluation'] as num).toDouble()) /
            reviews.length;
      }

      return Response.ok(
        jsonEncode({
          'revenus_totaux': totalRevenu,
          'nb_commandes': uniqueOrders.length,
          'note_moyenne': noteMoyenne.toStringAsFixed(1),
          'nb_produits': productsRes.length,
          'top_produits': topProducts,
          'chart_data': chartData,
          'recent_orders': recentOrders,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('❌ BusinessStatsController ERROR: $e');
      return Response(500,
          body: jsonEncode({'error': e.toString()}),
          headers: {'content-type': 'application/json'});
    }
  }
}