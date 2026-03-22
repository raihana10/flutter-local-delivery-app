import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseKey = env['SUPABASE_SERVICE_KEY'] ?? env['SUPABASE_ANON_KEY']!;

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    // Attempt to fetch one row to see the fields in adresse
    final adresseRes = await client.from('adresse').select().limit(1);
    print('Adresse columns: \n${adresseRes.isEmpty ? "No data" : adresseRes[0].keys.join(", ")}');

    // Attempt to fetch one row to see the fields in user_adresse
    final userAdresseRes = await client.from('user_adresse').select().limit(1);
    print('User Adresse columns: \n${userAdresseRes.isEmpty ? "No data" : userAdresseRes[0].keys.join(", ")}');
    
  } catch (e) {
    print('Error: $e');
  }
}
