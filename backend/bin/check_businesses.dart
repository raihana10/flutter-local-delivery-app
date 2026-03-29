
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load();
  final supabase = SupabaseClient(
    env['SUPABASE_URL']!,
    env['SUPABASE_SERVICE_KEY']!,
  );

  final response = await supabase
      .from('business')
      .select('id_business, type_business, est_actif, app_user(nom)');

  print('Total businesses: ${response.length}');
  for (var b in response) {
    print('ID: ${b['id_business']}, Type: ${b['type_business']}, Active: ${b['est_actif']}, Name: ${b['app_user']?['nom']}');
  }
}
