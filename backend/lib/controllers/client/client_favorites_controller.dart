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
      // x-client-id is id_user; resolve to id_client first
      final clientRecord = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', clientId)
          .maybeSingle();

      if (clientRecord == null) {
        return Response(404, body: jsonEncode({'error': 'Client profile not found'}), headers: {'content-type': 'application/json'});
      }

      final idClient = clientRecord['id_client'];

      final favoris = await SupabaseConfig.client
          .from('favoris')
          .select('*, business(*, app_user(*))')
          .eq('id_client', idClient);

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

      // x-client-id is id_user; resolve to id_client
      final clientRecord = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', clientId)
          .maybeSingle();

      if (clientRecord == null) {
        return Response(404, body: jsonEncode({'error': 'Client profile not found'}), headers: {'content-type': 'application/json'});
      }

      final newFavoris = await SupabaseConfig.client.from('favoris').insert({
        'id_client': clientRecord['id_client'],
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
      // Resolve id_client from id_user
      final clientRecord = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', clientId)
          .maybeSingle();

      if (clientRecord == null) {
        return Response(404, body: jsonEncode({'error': 'Client profile not found'}), headers: {'content-type': 'application/json'});
      }

      await SupabaseConfig.client
          .from('favoris')
          .delete()
          .eq('id_client', clientRecord['id_client'])
          .eq('id_business', idBusiness);

      return Response.ok(jsonEncode({'message': 'Favorite removed successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
