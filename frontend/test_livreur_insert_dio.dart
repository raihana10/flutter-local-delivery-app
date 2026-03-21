import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  final dio = Dio();
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWxqZXlkdWZ2dmNia2Znb2dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjg5MDMsImV4cCI6MjA4ODg0NDkwM30.N53hcpDdFXg07LsT8kjpoBIqN9v1DbDNEq7vMNw6K0s';

  dio.options.headers = {
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  };

  try {
    print('Inserting test livreur with id_user: 6...');
    final response = await dio.post('https://tyaljeydufvvcbkfgogg.supabase.co/rest/v1/livreur', data: {
      'id_user': 6,
      'sexe': 'homme',
      'date_naissance': '2000-01-01',
      'cni': 'AB123456',
      'documents_validation': 'livreurs/cni/1.jpg,livreurs/cni/2.jpg,livreurs/permis/3.jpg',
      'est_actif': false,
    });
    
    print('Insert successful! Result: \${response.data}');
    
  } catch (e) {
    if (e is DioException) {
      final res = e.response?.data;
      File('error_dump.json').writeAsStringSync(jsonEncode(res));
      print('Written to error_dump.json');
    } else {
      print('ERROR: \$e');
    }
  }
}
