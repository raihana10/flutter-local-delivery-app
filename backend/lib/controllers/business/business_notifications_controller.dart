import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class BusinessNotificationsController {
  Future<Response> getNotifications(Request request) async {
    try {
      final businessIdStr = request.headers['x-business-id'];
      if (businessIdStr == null) return Response(400, body: jsonEncode({'error': 'Missing Business ID'}));
      
      final userId = int.parse(businessIdStr);
      
      final notifications = await SupabaseConfig.client
          .from('user_notification')
          .select('id_not, est_lu, lu_at, notification(*)')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      return Response.ok(jsonEncode({'data': notifications}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> markAsRead(Request request, String id) async {
    try {
      final businessIdStr = request.headers['x-business-id'];

      await SupabaseConfig.client
          .from('user_notification')
          .update({'est_lu': true, 'lu_at': DateTime.now().toIso8601String()})
          .eq('id_user', int.parse(businessIdStr!))
          .eq('id_not', int.parse(id));

      return Response.ok(jsonEncode({'message': 'Notification marked as read'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> markAllAsRead(Request request) async {
    try {
      final businessIdStr = request.headers['x-business-id'];

      await SupabaseConfig.client
          .from('user_notification')
          .update({'est_lu': true, 'lu_at': DateTime.now().toIso8601String()})
          .eq('id_user', int.parse(businessIdStr!))
          .eq('est_lu', false);

      return Response.ok(jsonEncode({'message': 'All notifications marked as read'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }
}
