import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class BusinessProfileController {
  Future<Response> getProfile(Request request) async {
    try {
      final businessIdStr = request.headers['x-business-id'];
      if (businessIdStr == null) return Response(400, body: jsonEncode({'error': 'Missing Business ID'}));
      
      final business = await SupabaseConfig.client
          .from('business')
          .select('*, app_user(nom, email, num_tl)')
          .eq('id_user', int.parse(businessIdStr))
          .single();

      return Response.ok(jsonEncode(business), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> updateProfile(Request request) async {
    try {
      final businessIdStr = request.headers['x-business-id'];
      if (businessIdStr == null) return Response(400, body: jsonEncode({'error': 'Missing Business ID'}));
      
      final payload = jsonDecode(await request.readAsString());
      
      final updated = await SupabaseConfig.client
          .from('business')
          .update({
            if (payload.containsKey('is_open')) 'is_open': payload['is_open'],
            if (payload.containsKey('description')) 'description': payload['description'],
            if (payload.containsKey('temps_preparation')) 'temps_preparation': payload['temps_preparation'],
            if (payload.containsKey('opening_hours')) 'opening_hours': payload['opening_hours'],
          })
          .eq('id_user', int.parse(businessIdStr))
          .select()
          .single();

      return Response.ok(jsonEncode(updated), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }
}
