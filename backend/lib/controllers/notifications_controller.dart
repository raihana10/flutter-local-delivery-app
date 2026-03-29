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

      // Step 2: Link generically via user_notification
      if (idUser != null) {
        // Notification ciblée sur un utilisateur précis
        await SupabaseConfig.client.from('user_notification').insert({
          'id_user': idUser,
          'id_not': notif['id_not'],
          'est_lu': false,
        });
      } else {
        // Envoi global à un ou plusieurs groupes (Tous, Clients, Livreurs, Commerce)
        var query = SupabaseConfig.client.from('app_user').select('id_user');
        
        if (type == 'Clients') {
          query = query.eq('role', 'client');
        } else if (type == 'Livreurs') {
          query = query.eq('role', 'livreur');
        } else if (type == 'Commerce') {
          query = query.eq('role', 'business');
        }
        
        final targetUsers = await query;
        if (targetUsers.isNotEmpty) {
          final insertData = targetUsers.map((u) => <String, dynamic>{
            'id_user': u['id_user'],
            'id_not': notif['id_not'],
            'est_lu': false,
          }).toList();
          
          await SupabaseConfig.client.from('user_notification').insert(insertData);
        }
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
