import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class PaiementsController {
  
  Future<Response> getPaiements(Request request) async {
    try {
      final params = request.url.queryParameters;
      var query = SupabaseConfig.client
          .from('commande')
          .select('id_commande, prix_total, prix_donne, statut, date')
          .isFilter('deleted_at', null);

      if (params.containsKey('statut')) {
        query = query.eq('statut', params['statut']!);
      }
      if (params.containsKey('date_debut')) {
        query = query.gte('date', params['date_debut']!);
      }
      if (params.containsKey('date_fin')) {
        query = query.lte('date', params['date_fin']!);
      }

      final transactions = await query;
      return Response.ok(jsonEncode({'data': transactions}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getCommissions(Request request) async {
    try {
      // Logic: 10% of SUM(prix_donne) per driver on delivered orders
      // For simple Dart implementation acting as intermediary:
      final orders = await SupabaseConfig.client
          .from('commande')
          .select('id_livreur, prix_donne')
          .eq('statut', 'livree')
          .not('id_livreur', 'is', null)
          .isFilter('deleted_at', null);

      Map<int, double> livreurEarnings = {};
      for (var order in orders) {
        int idLivreur = order['id_livreur'];
        double price = (order['prix_donne'] as num).toDouble();
        livreurEarnings[idLivreur] = (livreurEarnings[idLivreur] ?? 0.0) + (price * 0.10);
      }

      final results = livreurEarnings.entries.map((e) => {
        'id_livreur': e.key,
        'commission': e.value,
      }).toList();

      return Response.ok(jsonEncode({'data': results}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getLivreurEarnings(Request request, String id) async {
    try {
      final orders = await SupabaseConfig.client
          .from('commande')
          .select('id_commande, prix_donne, date')
          .eq('statut', 'livree')
          .eq('id_livreur', id)
          .isFilter('deleted_at', null);

      double totalCommission = 0.0;
      for (var order in orders) {
        totalCommission += (order['prix_donne'] as num).toDouble() * 0.10;
      }

      return Response.ok(jsonEncode({
        'id_livreur': int.parse(id),
        'historique': orders,
        'recompenses_totales': totalCommission
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
