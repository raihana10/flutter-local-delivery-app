import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class ClientProfileController {
  
  // ==========================================
  // Profile Methods
  // ==========================================
  
  Future<Response> getProfile(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('*, client(*)')
          .eq('id_user', clientId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (user == null) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      return Response.ok(jsonEncode({'data': user}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> updateProfile(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      // Separate data for user and client tables
      final userData = <String, dynamic>{};
      final clientData = <String, dynamic>{};

      if (data.containsKey('nom')) userData['nom'] = data['nom'];
      if (data.containsKey('num_tl')) userData['num_tl'] = data['num_tl'];
      
      if (data.containsKey('sexe')) clientData['sexe'] = data['sexe'];
      if (data.containsKey('date_naissance')) clientData['date_naissance'] = data['date_naissance'];

      // Update user table
      if (userData.isNotEmpty) {
        await SupabaseConfig.client
            .from('app_user')
            .update(userData)
            .eq('id_user', clientId);
      }

      // Update client table
      if (clientData.isNotEmpty) {
        await SupabaseConfig.client
            .from('client')
            .update(clientData)
            .eq('id_user', clientId);
      }

      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  // ==========================================
  // Addresses Methods
  // ==========================================

  Future<Response> getAddresses(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      // Query user_adresse and join with adresse table
      final addresses = await SupabaseConfig.client
          .from('user_adresse')
          .select('*, adresse(*)')
          .eq('id_user', clientId)
          .isFilter('deleted_at', null)
          .order('is_default', ascending: false);

      return Response.ok(jsonEncode({'data': addresses}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> addAddress(Request request) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
        return Response(400, body: jsonEncode({'error': 'Latitude and longitude are required'}), headers: {'content-type': 'application/json'});
      }

      // First insert the address
      final newAddress = await SupabaseConfig.client
          .from('adresse')
          .insert({
            'ville': data['ville'] ?? '',
            'latitude': data['latitude'],
            'longitude': data['longitude'],
          })
          .select()
          .single();

      // Then link the address to the user
      final userAddress = await SupabaseConfig.client
          .from('user_adresse')
          .insert({
            'id_user': clientId,
            'id_adresse': newAddress['id_adresse'],
            'is_default': data['is_default'] ?? false,
          })
          .select()
          .single();
      
      return Response.ok(jsonEncode({'data': {'adresse': newAddress, 'user_adresse': userAddress}}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> updateAddress(Request request, String addressId) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      final updateData = <String, dynamic>{};
      if (data.containsKey('ville')) updateData['ville'] = data['ville'];
      if (data.containsKey('latitude')) updateData['latitude'] = data['latitude'];
      if (data.containsKey('longitude')) updateData['longitude'] = data['longitude'];

      if (updateData.isNotEmpty) {
        await SupabaseConfig.client
            .from('adresse')
            .update(updateData)
            .eq('id_adresse', addressId);
      }
      
      if (data.containsKey('is_default')) {
        // First set all other addresses to not default if this one is true
        if (data['is_default'] == true) {
           await SupabaseConfig.client
            .from('user_adresse')
            .update({'is_default': false})
            .eq('id_user', clientId);
        }

        await SupabaseConfig.client
            .from('user_adresse')
            .update({'is_default': data['is_default']})
            .match({'id_user': clientId, 'id_adresse': addressId});
      }

      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> deleteAddress(Request request, String addressId) async {
    final clientId = request.headers['x-client-id'];
    if (clientId == null) return Response.forbidden('Missing client id');

    try {
      // Unlink address from user
      await SupabaseConfig.client
          .from('user_adresse')
          .delete()
          .match({'id_user': clientId, 'id_adresse': addressId});
      
      return Response.ok(jsonEncode({'success': true}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
