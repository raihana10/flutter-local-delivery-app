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
          .select('*, app_user(*, user_adresse(*, adresse(*)))')
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
            if (payload.containsKey('pdp')) 'pdp': payload['pdp'],
          })
          .eq('id_user', int.parse(businessIdStr))
          .select()
          .single();

      return Response.ok(jsonEncode(updated), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> addAddress(Request request) async {
    final businessIdStr = request.headers['x-business-id'];
    if (businessIdStr == null) return Response.forbidden('Missing business id');

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
        return Response(400, body: jsonEncode({'error': 'Latitude and longitude are required'}));
      }

      // Round coordinates to 6 decimal places to avoid floating-point precision issues
      final roundedLat = (data['latitude'] as num).toDouble();
      final roundedLng = (data['longitude'] as num).toDouble();
      final lat = double.parse(roundedLat.toStringAsFixed(6));
      final lng = double.parse(roundedLng.toStringAsFixed(6));

      var existingAddress = await SupabaseConfig.client
          .from('adresse')
          .select()
          .eq('latitude', lat)
          .eq('longitude', lng)
          .maybeSingle();

      Map<String, dynamic> finalAddress;

      if (existingAddress != null) {
        finalAddress = existingAddress;
      } else {
        finalAddress = await SupabaseConfig.client
            .from('adresse')
            .insert({
              'ville': data['ville'] ?? '',
              'details': data['details'] ?? '',
              'latitude': lat,
              'longitude': lng,
            })
            .select()
            .single();
      }

      var existingUserAddress = await SupabaseConfig.client
          .from('user_adresse')
          .select()
          .eq('id_user', int.parse(businessIdStr))
          .eq('id_adresse', finalAddress['id_adresse'])
          .maybeSingle();

      if (existingUserAddress != null) {
        await SupabaseConfig.client
            .from('user_adresse')
            .update({
              'is_default': data['is_default'] ?? false,
              'titre': data['titre'] ?? 'Adresse',
            })
            .eq('id_user', int.parse(businessIdStr))
            .eq('id_adresse', finalAddress['id_adresse']);
      } else {
        await SupabaseConfig.client
            .from('user_adresse')
            .insert({
              'id_user': int.parse(businessIdStr),
              'id_adresse': finalAddress['id_adresse'],
              'is_default': data['is_default'] ?? false,
              'titre': data['titre'] ?? 'Adresse',
            });
      }

      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> getAddresses(Request request) async {
    final businessIdStr = request.headers['x-business-id'];
    if (businessIdStr == null) return Response.forbidden('Missing business id');
    try {
      final addresses = await SupabaseConfig.client
          .from('user_adresse')
          .select('*, adresse(*)')
          .eq('id_user', int.parse(businessIdStr))
          .isFilter('deleted_at', null)
          .order('is_default', ascending: false);
      return Response.ok(jsonEncode({'data': addresses}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> updateAddress(Request request, String addressId) async {
    final businessIdStr = request.headers['x-business-id'];
    if (businessIdStr == null) return Response.forbidden('Missing business id');
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      if (data.containsKey('is_default') && data['is_default'] == true) {
        // Reset all defaults first
        await SupabaseConfig.client
            .from('user_adresse')
            .update({'is_default': false})
            .eq('id_user', int.parse(businessIdStr));
      }
      final updateData = <String, dynamic>{};
      if (data.containsKey('is_default')) updateData['is_default'] = data['is_default'];
      if (data.containsKey('titre')) updateData['titre'] = data['titre'];
      if (updateData.isNotEmpty) {
        await SupabaseConfig.client
            .from('user_adresse')
            .update(updateData)
            .match({'id_user': int.parse(businessIdStr), 'id_adresse': int.parse(addressId)});
      }
      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> deleteAddress(Request request, String addressId) async {
    final businessIdStr = request.headers['x-business-id'];
    if (businessIdStr == null) return Response.forbidden('Missing business id');
    try {
      await SupabaseConfig.client.from('user_adresse').delete().match({
        'id_user': int.parse(businessIdStr),
        'id_adresse': int.parse(addressId),
      });
      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }
}
