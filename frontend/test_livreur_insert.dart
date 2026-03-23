import 'package:supabase/supabase.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  final supabaseUrl = 'https://tyaljeydufvvcbkfgogg.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWxqZXlkdWZ2dmNia2Znb2dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjg5MDMsImV4cCI6MjA4ODg0NDkwM30.N53hcpDdFXg07LsT8kjpoBIqN9v1DbDNEq7vMNw6K0s';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    // 1. Create a dummy user
    final email = 'test_livreur_\${DateTime.now().millisecondsSinceEpoch}@test.com';
    final password = 'password123';
    
    print('Signing up in Supabase Auth...');
    final response = await client.auth.signUp(email: email, password: password);
    
    if (response.user == null) {
      throw Exception('Sign up failed');
    }
    
    print('Inserting into app_user...');
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final hashedPassword = digest.toString();

    final userResponse = await client.from('app_user').insert({
      'email': email,
      'password': hashedPassword,
      'nom': 'Test Livreur',
      'num_tl': '12345678',
      'role': 'livreur',
    }).select().single();
    
    final int userId = userResponse['id_user'];
    print('Created app_user with ID: $userId');

    print('Inserting into livreur...');
    // We try to insert with the exact data that register_screen sends
    final res = await client.from('livreur').insert({
      'id_user': userId,
      'sexe': 'homme',
      'date_naissance': '2000-01-01',
      'cni': 'AB123456',
      'documents_validation': 'livreurs/cni/1.jpg,livreurs/cni/2.jpg,livreurs/permis/3.jpg',
      'est_actif': false,
    });
    
    print('Insert successful! Result: $res');
    
  } catch (e) {
    print('ERROR CAUGHT: $e');
  }
}
