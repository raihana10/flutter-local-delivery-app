import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

import 'dashboard_visualization_seeder.dart';
import 'statistics_seeder.dart';

class AllSeedersRunner {
  final SupabaseClient _supabase;

  AllSeedersRunner(this._supabase);

  Future<void> seedAll() async {
    print('🌱 Starting all seeders...');
    
    try {
      // Exécuter le seeder de visualisation dashboard
      final dashboardSeeder = DashboardVisualizationSeeder(_supabase);
      await dashboardSeeder.seedAll();
      
      print('\n' + '='*50);
      
      // Exécuter le seeder de statistiques
      final statsSeeder = StatisticsSeeder(_supabase);
      await statsSeeder.seedAll();
      
      print('\n🎉 All seeders completed successfully!');
      print('\n📊 Données disponibles:');
      print('   • Evolution des revenus (7 derniers jours)');
      print('   • Statut des commandes (pie chart)');
      print('   • Revenus hebdomadaires');
      print('   • Top 5 livreurs par performance');
      print('   • Top 7 commerce par revenus');
      print('   • Types: super-marché, restaurant, pharmacie');
      
    } catch (e) {
      print('❌ Error during seeding: $e');
      rethrow;
    }
  }
}

void main() async {
  print('🔌 Loading environment variables...');
  
  // Charger le fichier .env
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final supabaseUrl = env['SUPABASE_URL'] ?? 'https://tyaljeydufvvcbkfgogg.supabase.co';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWxqZXlkdWZ2dmNia2Znb2dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjg5MDMsImV4cCI6MjA4ODg0NDkwM30.N53hcpDdFXg07LsT8kjpoBIqN9v1DbDNEq7vMNw6K0s';
  
  print('🔌 Connecting to Supabase...');
  print('   URL: $supabaseUrl');
  
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    // Test de connexion
    await supabase.from('app_user').select('count').limit(1);
    print('✅ Supabase connected successfully');
    
    final runner = AllSeedersRunner(supabase);
    await runner.seedAll();
    
  } catch (e) {
    print('❌ Supabase connection failed: $e');
    print('   Vérifiez que les tables existent dans votre projet Supabase');
    print('   Tables requises: dashboard_revenue_evolution, dashboard_orders_status, dashboard_weekly_revenue, dashboard_top_livreurs, dashboard_top_commerce');
  }
}
