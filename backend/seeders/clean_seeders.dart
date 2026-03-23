import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  print('🧹 Nettoyage des données dupliquées...');
  
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final supabaseUrl = env['SUPABASE_URL'] ?? 'https://tyaljeydufvvcbkfgogg.supabase.co';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWxqZXlkdWZ2dmNia2Znb2dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjg5MDMsImV4cCI6MjA4ODg0NDkwM30.N53hcpDdFXg07LsT8kjpoBIqN9v1DbDNEq7vMNw6K0s';
  
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    // Supprimer toutes les données des tables
    await supabase.from('dashboard_revenue_evolution').delete().neq('id', 0);
    await supabase.from('dashboard_orders_status').delete().neq('id', 0);
    await supabase.from('dashboard_weekly_revenue').delete().neq('id', 0);
    await supabase.from('dashboard_top_livreurs').delete().neq('id', 0);
    await supabase.from('dashboard_top_commerce').delete().neq('id', 0);
    await supabase.from('stats_weekly_revenue').delete().neq('id', 0);
    await supabase.from('stats_top_livreurs').delete().neq('id', 0);
    await supabase.from('stats_top_commerce').delete().neq('id', 0);
    
    print('✅ Tables nettoyées');
    
    // Réinitialiser les séquences pour éviter les ID très élevés
    await supabase.rpc('reset_sequence', params: {'table_name': 'dashboard_revenue_evolution'});
    await supabase.rpc('reset_sequence', params: {'table_name': 'dashboard_orders_status'});
    await supabase.rpc('reset_sequence', params: {'table_name': 'dashboard_weekly_revenue'});
    await supabase.rpc('reset_sequence', params: {'table_name': 'dashboard_top_livreurs'});
    await supabase.rpc('reset_sequence', params: {'table_name': 'dashboard_top_commerce'});
    await supabase.rpc('reset_sequence', params: {'table_name': 'stats_weekly_revenue'});
    await supabase.rpc('reset_sequence', params: {'table_name': 'stats_top_livreurs'});
    await supabase.rpc('reset_sequence', params: {'table_name': 'stats_top_commerce'});
    
    print('✅ Séquences réinitialisées');
    print('🎉 Nettoyage terminé !');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
