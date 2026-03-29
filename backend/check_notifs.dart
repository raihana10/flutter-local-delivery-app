import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseAnonKey = env['SUPABASE_ANON_KEY']!;
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final countQuery = await client.from('app_user').select('id_user');
  print('### APP USER COUNT ###');
  print(countQuery.length);
  
  final notifs = await client.from('user_notification').select('*').limit(5).order('id_not', ascending: false);
  print('### NOTIFS COUNT ###');
  print(notifs.length);
  exit(0);
}
