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

      // 2. Wrap as List
      final List results = userNotifs as List;

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

  // Mark a notification as read
  Future<Response> markAsRead(Request request, String idNot) async {
    final userId = request.headers['x-client-id'];
    if (userId == null) return Response.forbidden('Missing client id');

    try {
      // Update existing entry
      await SupabaseConfig.client
          .from('user_notification')
          .update({'est_lu': true, 'lu_at': DateTime.now().toIso8601String()})
          .match({'id_user': userId, 'id_not': idNot});

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
