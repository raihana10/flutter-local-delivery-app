import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class CommandesController {
  
  Future<Response> getCommandes(Request request) async {
    try {
      final params = request.url.queryParameters;
      var query = SupabaseConfig.client.from('commande').select().isFilter('deleted_at', null);

      if (params.containsKey('statut')) {
        query = query.eq('statut', params['statut']!);
      }
      if (params.containsKey('type_commande')) {
        query = query.eq('type', params['type_commande']!);
      }
      if (params.containsKey('date_debut')) {
        query = query.gte('date', params['date_debut']!);
      }
      if (params.containsKey('date_fin')) {
        query = query.lte('date', params['date_fin']!);
      }

      final commandes = await query;
      return Response.ok(jsonEncode({'data': commandes}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getCommandeDetail(Request request, String id) async {
    try {
      // NOTE: Dependent on actual DB relations.
      final commande = await SupabaseConfig.client
          .from('commande')
          .select('*, ligne_commande(*), timeline(*), user(*)')
          .eq('id_commande', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (commande == null) {
        return Response.notFound(jsonEncode({'error': 'Commande not found'}));
      }

      return Response.ok(jsonEncode({'data': commande}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> rembourseCommande(Request request, String id) async {
    try {
      final updatedCommande = await SupabaseConfig.client
          .from('commande')
          .update({'prix_donne': 0.0})
          .eq('id_commande', id)
          .isFilter('deleted_at', null)
          .select();

      return Response.ok(jsonEncode({'success': true, 'message': 'Remboursement efféctué', 'data': updatedCommande}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
