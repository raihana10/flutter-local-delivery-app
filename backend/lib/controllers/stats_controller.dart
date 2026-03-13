import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class StatsController {
  
  Future<Response> getRevenus(Request request) async {
    try {
      final params = request.url.queryParameters;
      var query = SupabaseConfig.client.from('commande').select('prix_donne, type_commande, created_at').isFilter('deleted_at', null);

      if (params.containsKey('date_debut')) query = query.gte('created_at', params['date_debut']!);
      if (params.containsKey('date_fin')) query = query.lte('created_at', params['date_fin']!);

      final commandes = await query;
      
      double totalRevenu = 0.0;
      Map<String, double> parType = {};

      for (var cmd in commandes) {
        double prix = (cmd['prix_donne'] as num).toDouble();
        String type = cmd['type_commande'] ?? 'unknown';
        totalRevenu += prix;
        parType[type] = (parType[type] ?? 0.0) + prix;
      }

      return Response.ok(jsonEncode({
        'revenus_totaux': totalRevenu,
        'par_type': parType
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getLivreurStats(Request request) async {
    try {
      final livreurs = await SupabaseConfig.client
          .from('app_user')
          .select('id_user, nom, role')
          .eq('role', 'livreur')
          .isFilter('deleted_at', null);

      return Response.ok(jsonEncode({'data': livreurs}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getBusinessStats(Request request) async {
    try {
      final businesses = await SupabaseConfig.client
          .from('app_user')
          .select('id_user, nom, role')
          .eq('role', 'business')
          .isFilter('deleted_at', null);

      return Response.ok(jsonEncode({'data': businesses}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getPromotions(Request request) async {
    try {
      final now = DateTime.now().toIso8601String();
      final promos = await SupabaseConfig.client
          .from('promotion')
          .select()
          .lte('date_debut', now)
          .gte('date_fin', now)
          .isFilter('deleted_at', null);

      return Response.ok(jsonEncode({'data': promos}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
