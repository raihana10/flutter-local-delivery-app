import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class UsersController {
  
  // NOTE: PostgREST JOINs work if foreign keys are properly set up (e.g. user(client(...))).
  // Without exact schema FK knowledge, we assume standard one-to-one joining structures.
  // The generic fallback is querying 'user' and joining the specific role table.

  Future<Response> getClients(Request request) async {
    try {
      final clients = await SupabaseConfig.client
          .from('app_user')
          .select('*, client(*)')
          .eq('role', 'client')
          .isFilter('deleted_at', null);
      
      return Response.ok(jsonEncode({'data': clients}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getLivreurs(Request request) async {
    try {
      final livreurs = await SupabaseConfig.client
          .from('app_user')
          .select('*, livreur(*)')
          .eq('role', 'livreur')
          .isFilter('deleted_at', null);

      return Response.ok(jsonEncode({'data': livreurs}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getBusinesses(Request request) async {
    try {
      final businesses = await SupabaseConfig.client
          .from('app_user')
          .select('*, business(*)')
          .eq('role', 'business')
          .isFilter('deleted_at', null);

      return Response.ok(jsonEncode({'data': businesses}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getUserDetail(Request request, String id) async {
    try {
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('*, client(*), livreur(*), business(*)')
          .eq('id_user', id)
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

  Future<Response> toggleUserStatus(Request request, String id) async {
    try {
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('role')
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (user == null) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      final role = user['role'] as String;
      if (role == 'client') {
        return Response(400, body: jsonEncode({'error': 'Clients cannot be suspended in this schema.'}));
      }

      final table = role == 'livreur' ? 'livreur' : 'business';

      final roleRecord = await SupabaseConfig.client
          .from(table)
          .select('est_actif')
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (roleRecord == null) {
        return Response.notFound(jsonEncode({'error': '$table record not found'}));
      }

      final newStatus = !(roleRecord['est_actif'] as bool);

      final updatedUser = await SupabaseConfig.client
          .from(table)
          .update({'est_actif': newStatus})
          .eq('id_user', id)
          .select();

      return Response.ok(jsonEncode({'success': true, 'data': updatedUser}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> validateUser(Request request, String id) async {
    try {
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('role')
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .maybeSingle();
          
      if (user == null) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }
      
      final role = user['role'] as String;
      if (role == 'client') {
        return Response(400, body: jsonEncode({'error': 'Clients do not need validation'}));
      }

      final table = role == 'livreur' ? 'livreur' : 'business';
      final Map<String, dynamic> updateData = {'est_actif': true};
      
      if (role == 'business') {
        updateData['documents_validation'] = 'validated'; // in schema this is a varchar
      }

      final updatedUser = await SupabaseConfig.client
          .from(table)
          .update(updateData)
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .select();

      return Response.ok(jsonEncode({'success': true, 'message': 'User validated', 'data': updatedUser}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> deleteUser(Request request, String id) async {
    try {
      await SupabaseConfig.client
          .from('app_user')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id_user', id);

      return Response.ok(jsonEncode({'success': true, 'message': 'User deleted successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
