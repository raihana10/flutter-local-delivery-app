import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'];
  final supabaseServiceKey = env['SUPABASE_SERVICE_KEY'] ?? env['SUPABASE_ANON_KEY'];
  
  print('Anon Key Upload Test:');
  final anonClient = SupabaseClient(supabaseUrl!, supabaseAnonKey!);
  try {
    final file = File('test.txt');
    await file.writeAsString('test content');
    final response = await anonClient.storage.from('documents').upload('test.txt', file, fileOptions: const FileOptions(upsert: true));
    print('Anon Success: $response');
  } catch (e) {
    print('Anon Error: $e');
  }

  print('\nService Key Upload Test:');
  final serviceClient = SupabaseClient(supabaseUrl, supabaseServiceKey!);
  try {
    final file = File('test2.txt');
    await file.writeAsString('test content 2');
    final response = await serviceClient.storage.from('documents').upload('test2.txt', file, fileOptions: const FileOptions(upsert: true));
    print('Service Success: $response');
  } catch (e) {
    print('Service Error: $e');
  }
  
  exit(0);
}
