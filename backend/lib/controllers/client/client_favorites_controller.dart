import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class ClientFavoritesController {
  
  // Get all favorites for the authenticated client
  Future<Response> getFavorites(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) {
      return Response.forbidden(jsonEncode({'error': 'Unauthorized'}));
    }

    try {
      final favoris = await SupabaseConfig.client
          .from('favoris')
          .select('*, business(*, app_user(*))')
          .eq('id_client', clientId);

      return Response.ok(jsonEncode({'data': favoris}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  // Add a new favorite
  Future<Response> addFavorite(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) {
      return Response.forbidden(jsonEncode({'error': 'Unauthorized'}));
    }

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      final idBusiness = data['id_business'];

      if (idBusiness == null) {
        return Response(400, body: jsonEncode({'error': 'id_business is required'}), headers: {'content-type': 'application/json'});
      }

      final newFavoris = await SupabaseConfig.client.from('favoris').insert({
        'id_client': clientId,
        'id_business': idBusiness,
      }).select().single();

      return Response.ok(jsonEncode({'data': newFavoris}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  // Remove a favorite
  Future<Response> removeFavorite(Request request, String idBusiness) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) {
      return Response.forbidden(jsonEncode({'error': 'Unauthorized'}));
    }

    try {
      await SupabaseConfig.client
          .from('favoris')
          .delete()
          .eq('id_client', clientId)
          .eq('id_business', idBusiness);

      return Response.ok(jsonEncode({'message': 'Favorite removed successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
