import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class ClientNotificationsController {
  // Get all notifications for the current user (Private + Global)
  Future<Response> getNotifications(Request request) async {
    final userId = request.headers['x-client-id'];
    if (userId == null) return Response.forbidden('Missing client id');

    try {
      // 1. Fetch private notifications (linked via user_notification)
      final userNotifs = await SupabaseConfig.client
          .from('user_notification')
          .select('*, notification(*)')
          .eq('id_user', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      // 2. Fetch global notifications for clients
      final globalNotifs = await SupabaseConfig.client
          .from('notification')
          .select('*')
          .eq('est_globale', true)
          .eq('role_cible', 'client')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      // 3. Merge and format
      // We convert global notifications to the same format as user_notification entries
      final List results = [...(userNotifs as List)];
      final Set<int> existingNotifIds = results.map((e) => e['id_not'] as int).toSet();

      for (var gn in globalNotifs as List) {
        if (!existingNotifIds.contains(gn['id_not'])) {
          results.add({
            'id_user_not': 0, // Virtual ID
            'id_user': userId,
            'id_not': gn['id_not'],
            'est_lu': false,
            'created_at': gn['created_at'],
            'notification': gn
          });
        }
      }

      // Re-sort by date
      results.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

      return Response.ok(
        jsonEncode({'data': results}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  // Mark a notification as read (Handles both private and global)
  Future<Response> markAsRead(Request request, String idNot) async {
    final userId = request.headers['x-client-id'];
    if (userId == null) return Response.forbidden('Missing client id');

    try {
      // Check if the entry already exists in user_notification
      final existing = await SupabaseConfig.client
          .from('user_notification')
          .select()
          .match({'id_user': userId, 'id_not': idNot})
          .maybeSingle();

      if (existing != null) {
        // Update existing entry
        await SupabaseConfig.client
            .from('user_notification')
            .update({'est_lu': true, 'lu_at': DateTime.now().toIso8601String()})
            .match({'id_user': userId, 'id_not': idNot});
      } else {
        // Safe check: ensure it's a global notification before creating an entry
        final isGlobal = await SupabaseConfig.client
            .from('notification')
            .select('est_globale')
            .eq('id_not', int.parse(idNot))
            .maybeSingle();

        if (isGlobal != null && isGlobal['est_globale'] == true) {
          // Create a new entry for this user to mark the global notification as read
          await SupabaseConfig.client.from('user_notification').insert({
            'id_user': userId,
            'id_not': int.parse(idNot),
            'est_lu': true,
            'lu_at': DateTime.now().toIso8601String()
          });
        }
      }

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
