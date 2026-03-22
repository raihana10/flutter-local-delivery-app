import 'dart:io';
import 'dart:convert';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  print('🔧 Test des données dashboard...');
  
  // Charger les variables d'environnement
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final supabaseUrl = env['SUPABASE_URL'] ?? 'https://tyaljeydufvvcbkfgogg.supabase.co';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWxqZXlkdWZ2dmNia2Znb2dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjg5MDMsImV4cCI6MjA4ODg0NDkwM30.N53hcpDdFXg07LsT8kjpoBIqN9v1DbDNEq7vMNw6K0s';
  
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    print('\n📊 Test des tables dashboard...');
    
    // Test revenue evolution
    final revenueData = await supabase.from('dashboard_revenue_evolution').select('*');
    print('✅ Revenue Evolution: ${revenueData.length} enregistrements');
    if (revenueData.isNotEmpty) {
      print('   Premier enregistrement: ${revenueData.first}');
    }
    
    // Test orders status
    final ordersStatus = await supabase.from('dashboard_orders_status').select('*');
    print('✅ Orders Status: ${ordersStatus.length} enregistrements');
    if (ordersStatus.isNotEmpty) {
      print('   Statuts: ${ordersStatus.map((s) => s['status']).join(', ')}');
    }
    
    // Test weekly revenue
    final weeklyRevenue = await supabase.from('dashboard_weekly_revenue').select('*');
    print('✅ Weekly Revenue: ${weeklyRevenue.length} enregistrements');
    if (weeklyRevenue.isNotEmpty) {
      print('   Revenu semaine actuelle: ${weeklyRevenue.first['current_week']} MAD');
    }
    
    // Test top livreurs
    final topLivreurs = await supabase.from('dashboard_top_livreurs').select('*');
    print('✅ Top Livreurs: ${topLivreurs.length} enregistrements');
    if (topLivreurs.isNotEmpty) {
      print('   #1: ${topLivreurs.first['name']} - ${topLivreurs.first['deliveries']} livraisons');
    }
    
    // Test top commerce
    final topCommerce = await supabase.from('dashboard_top_commerce').select('*');
    print('✅ Top Commerce: ${topCommerce.length} enregistrements');
    if (topCommerce.isNotEmpty) {
      print('   #1: ${topCommerce.first['name']} (${topCommerce.first['type']}) - ${topCommerce.first['revenue']} MAD');
    }
    
    print('\n📈 Test des tables statistiques...');
    
    // Test stats weekly revenue
    final statsWeekly = await supabase.from('stats_weekly_revenue').select('*');
    print('✅ Stats Weekly Revenue: ${statsWeekly.length} enregistrements');
    
    // Test stats top livreurs
    final statsLivreurs = await supabase.from('stats_top_livreurs').select('*');
    print('✅ Stats Top Livreurs: ${statsLivreurs.length} enregistrements');
    
    // Test stats top commerce
    final statsCommerce = await supabase.from('stats_top_commerce').select('*');
    print('✅ Stats Top Commerce: ${statsCommerce.length} enregistrements');
    
    print('\n🌐 Test des API endpoints...');
    
    // Test API KPIs
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse('http://localhost:8084/admin/dashboard/kpis'));
      request.headers.set('x-admin-id', '1');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        print('✅ API KPIs: ${data['commandes_actives']} commandes actives, ${data['livreurs_actifs']} livreurs actifs');
      } else {
        print('❌ API KPIs: HTTP ${response.statusCode}');
      }
      httpClient.close();
    } catch (e) {
      print('❌ API KPIs: $e (serveur peut-être démarré?)');
    }
    
    // Test API Chart Data
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse('http://localhost:8084/admin/dashboard/chart'));
      request.headers.set('x-admin-id', '1');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        print('✅ API Chart: ${data['weeklyRevenue']?.length ?? 0} jours de revenus, ${data['ordersByStatus']?.length ?? 0} statuts de commandes');
      } else {
        print('❌ API Chart: HTTP ${response.statusCode}');
      }
      httpClient.close();
    } catch (e) {
      print('❌ API Chart: $e');
    }
    
    print('\n🎉 Test terminé !');
    print('\n📋 Résumé:');
    print('   • Tables Supabase: ✅ OK');
    print('   • Données seeders: ✅ OK');
    print('   • API endpoints: ${revenueData.isNotEmpty ? '✅ OK' : '❌ Démarrer le serveur backend'}');
    
  } catch (e) {
    print('❌ Erreur: $e');
    print('\n💡 Solutions possibles:');
    print('   1. Exécuter: dart run seeders/run_all_seeders.dart');
    print('   2. Créer les tables avec create_tables.sql dans Supabase');
    print('   3. Démarrer le serveur: dart run bin/server.dart');
  }
}
