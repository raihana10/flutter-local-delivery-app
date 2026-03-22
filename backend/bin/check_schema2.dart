import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseKey = env['SUPABASE_SERVICE_KEY'] ?? env['SUPABASE_ANON_KEY']!;

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final res = await client.from('business').select().limit(1);
    print('Business columns: \n${res.isEmpty ? "No data" : res[0].keys.join(", ")}');
  } catch (e) {
    print('Error: $e');
  }
}
