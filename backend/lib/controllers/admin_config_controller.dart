import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class AdminConfigController {
  final Map<String, String> _headers = {'content-type': 'application/json'};

  Future<Response> getConfigs(Request request) async {
    try {
      final configs = await SupabaseConfig.client.from('app_config').select();
      
      // Transform into a map { 'prix_par_km': '1.5', ... }
      final Map<String, String> result = {};
      for (var row in configs) {
        result[row['cle'] as String] = row['valeur'] as String;
      }

      return Response.ok(
        jsonEncode({'data': result}),
        headers: _headers,
      );
    } catch (e) {
      print('GET ADMIN CONFIGS ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }

  Future<Response> updateConfig(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      if (body['cle'] == null || body['valeur'] == null) {
        return Response(400, body: jsonEncode({'error': 'Missing cle or valeur'}), headers: _headers);
      }

      final cle = body['cle'] as String;
      final valeur = body['valeur'].toString(); // ensure it's a string

      await SupabaseConfig.client.from('app_config').upsert({
        'cle': cle,
        'valeur': valeur,
      });

      return Response.ok(
        jsonEncode({'success': true}),
        headers: _headers,
      );
    } catch (e) {
      print('UPDATE ADMIN CONFIG ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }
}
