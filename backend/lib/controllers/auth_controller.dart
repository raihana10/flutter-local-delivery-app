import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import '../supabase/supabase_client.dart';

class AuthController {
  Future<Response> login(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      final email = body['email'];
      final password = body['password'];

      if (email == null || password == null) {
        return Response(
          400,
          body: jsonEncode({
            'success': false,
            'error': 'Email and password are required',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Query Supabase admin table
      final response = await SupabaseConfig.client
          .from('admin')
          .select()
          .eq('email', email)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) {
        return Response(
          403,
          body: jsonEncode({'success': false, 'error': 'Invalid credentials'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Verify password
      final hash = response['password'];
      final isMatch = BCrypt.checkpw(password, hash);

      if (!isMatch) {
        return Response(
          403,
          body: jsonEncode({'success': false, 'error': 'Invalid credentials'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'id_admin': response['id_admin'],
          'email': response['email'],
          // For simple memory flag simulation without JWT, we return the admin ID to be used as x-admin-id header by the client
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('LOGIN ERROR: $e');
      return Response(
        500,
        body: jsonEncode({'success': false, 'error': 'Internal server error'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
