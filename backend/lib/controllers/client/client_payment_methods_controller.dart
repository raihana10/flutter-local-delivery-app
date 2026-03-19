import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class ClientPaymentMethodsController {
  Future<Response> getPaymentMethods(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      // Find the associated id_client for this user
      final clientResponse = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', clientId)
          .single();
      
      final actualClientId = clientResponse['id_client'];

      final methods = await SupabaseConfig.client
          .from('carte_bancaire')
          .select()
          .eq('id_client', actualClientId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return Response.ok(jsonEncode({'data': methods}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> addPaymentMethod(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      final payload = jsonDecode(await request.readAsString());
      
      final clientResponse = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', clientId)
          .single();
      final actualClientId = clientResponse['id_client'];

      // If this is set as default, remove default from others
      if (payload['is_default'] == true) {
        await SupabaseConfig.client
            .from('carte_bancaire')
            .update({'is_default': false})
            .eq('id_client', actualClientId);
      }

      await SupabaseConfig.client.from('carte_bancaire').insert({
        'id_client': actualClientId,
        'numero_carte': payload['numero_carte'],
        'date_expiration': payload['date_expiration'],
        'nom_carte': payload['nom_carte'] ?? '',
        'is_default': payload['is_default'] ?? false,
      });

      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> deletePaymentMethod(Request request, String id) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      await SupabaseConfig.client
          .from('carte_bancaire')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id_carte', id);

      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> setDefaultPaymentMethod(Request request, String id) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      final clientResponse = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', clientId)
          .single();
      final actualClientId = clientResponse['id_client'];

      // Reset all
      await SupabaseConfig.client
          .from('carte_bancaire')
          .update({'is_default': false})
          .eq('id_client', actualClientId);

      // Set new default
      await SupabaseConfig.client
          .from('carte_bancaire')
          .update({'is_default': true})
          .eq('id_carte', id);

      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
