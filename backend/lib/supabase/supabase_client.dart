import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

class SupabaseConfig {
  static late final SupabaseClient client;

  static void initialize() {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    
    final supabaseUrl = env['SUPABASE_URL'];
    final supabaseAnonKey = env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing Supabase Config in .env file');
    }

    client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  }
}
