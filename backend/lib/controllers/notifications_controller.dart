import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class NotificationsController {
  Future<Response> getNotifications(Request request) async {
    try {
      final notifications = await SupabaseConfig.client
          .from('notification')
          .select()
          .order('date', ascending: false)
          .limit(50);

      return Response.ok(
        jsonEncode({'data': notifications}),
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

  Future<Response> createNotification(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      final idUser = body['id_user'];
      final titre = body['titre'];
      final message = body['message'];
      final type = body['type'];

      if (titre == null || message == null || type == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'Missing title, message, or type'}),
        );
      }

      // Step 1: Create notification
      final notif = await SupabaseConfig.client
          .from('notification')
          .insert({
            'titre': titre,
            'message': message,
            'type': type,
            'date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Step 2: Link generically via user_notification if directed at a specific user
      if (idUser != null) {
        await SupabaseConfig.client.from('user_notification').insert({
          'id_user': idUser,
          'id_not': notif['id_not'],
          'lu': false,
        });
      }

      return Response.ok(
        jsonEncode({'success': true, 'data': notif}),
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
