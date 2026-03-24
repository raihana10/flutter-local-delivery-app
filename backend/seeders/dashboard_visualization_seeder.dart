import 'dart:io';
import 'dart:convert';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

class DashboardVisualizationSeeder {
  final SupabaseClient _supabase;

  DashboardVisualizationSeeder(this._supabase);

  Future<void> seedAll() async {
    print('🌱 Seeding dashboard visualization data...');
    
    await _seedRevenueEvolution();
    await _seedOrdersStatus();
    await _seedWeeklyRevenue();
    await _seedTopLivreurs();
    await _seedTopCommerce();
    
    print('✅ Dashboard visualization data seeded successfully!');
  }

  // Evolution des revenus (semaine) pour le graphique
  Future<void> _seedRevenueEvolution() async {
    print('📈 Seeding revenue evolution...');
    
    // Simuler les revenus des 7 derniers jours
    final List<Map<String, dynamic>> revenueData = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'][date.weekday - 1];
      final revenue = 80000 + (i * 15000) + (date.hour * 2000); // Revenus simulés
      
      revenueData.add({
        'day': dayName,
        'date': date.toIso8601String().split('T')[0],
        'revenue': revenue,
      });
    }

    // Insérer dans Supabase
    await _supabase.from('dashboard_revenue_evolution').insert(revenueData);

    print('✅ Revenue evolution seeded: ${revenueData.length} days');
  }

  // Statut des commandes pour le pie chart
  Future<void> _seedOrdersStatus() async {
    print('📊 Seeding orders status...');
    
    final ordersStatus = [
      {'status': 'En attente', 'count': 45, 'color': '#FFA726'},
      {'status': 'En préparation', 'count': 78, 'color': '#42A5F5'},
      {'status': 'En livraison', 'count': 32, 'color': '#66BB6A'},
      {'status': 'Livrée', 'count': 156, 'color': '#26A69A'},
      {'status': 'Annulée', 'count': 12, 'color': '#EF5350'},
    ];

    // Insérer dans Supabase
    await _supabase.from('dashboard_orders_status').insert(ordersStatus);

    print('✅ Orders status seeded: ${ordersStatus.length} statuses');
  }

  // Revenus générés (semaine actuelle)
  Future<void> _seedWeeklyRevenue() async {
    print('💰 Seeding weekly revenue...');
    
    final weeklyRevenue = {
      'current_week': 585000.75,
      'previous_week': 512300.25,
      'growth_percentage': 14.3,
    };

    // Insérer dans Supabase
    await _supabase.from('dashboard_weekly_revenue').insert([weeklyRevenue]);

    print('✅ Weekly revenue seeded: ${weeklyRevenue['current_week']} MAD');
  }

  // Top livreurs par nombre de livraisons
  Future<void> _seedTopLivreurs() async {
    print('🏆 Seeding top livreurs...');
    
    final topLivreurs = [
      {'name': 'Karim Idrissi', 'deliveries': 156, 'rating': 4.8, 'revenue': 12480.00},
      {'name': 'Fatima Zahra', 'deliveries': 142, 'rating': 4.9, 'revenue': 11360.00},
      {'name': 'Mohammed Alaoui', 'deliveries': 128, 'rating': 4.7, 'revenue': 10240.00},
      {'name': 'Aicha Bennani', 'deliveries': 115, 'rating': 4.9, 'revenue': 9200.00},
      {'name': 'Youssef Tazi', 'deliveries': 98, 'rating': 4.6, 'revenue': 7840.00},
    ];

    // Insérer dans Supabase
    await _supabase.from('dashboard_top_livreurs').insert(topLivreurs);

    print('✅ Top livreurs seeded: ${topLivreurs.length} livreurs');
  }

  // Top commerce/restaurants par revenus
  Future<void> _seedTopCommerce() async {
    print('🏪 Seeding top commerce...');
    
    final topCommerce = [
      {'name': 'Supermarché Al-Mouna', 'type': 'super-marche', 'revenue': 45600.00, 'orders': 234},
      {'name': 'Restaurant Le Gourmet', 'type': 'restaurant', 'revenue': 38900.00, 'orders': 189},
      {'name': 'Pharmacie Centrale', 'type': 'pharmacie', 'revenue': 32100.00, 'orders': 156},
      {'name': 'Restaurant Casa Blanca', 'type': 'restaurant', 'revenue': 28700.00, 'orders': 145},
      {'name': 'Supermarché Atlan', 'type': 'super-marche', 'revenue': 25400.00, 'orders': 128},
    ];

    // Insérer dans Supabase
    await _supabase.from('dashboard_top_commerce').insert(topCommerce);

    print('✅ Top commerce seeded: ${topCommerce.length} commerce');
  }
}

void main() async {
  print('🔌 Loading environment variables...');
  
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final supabaseUrl = env['SUPABASE_URL'] ?? 'https://tyaljeydufvvcbkfgogg.supabase.co';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWxqZXlkdWZ2dmNia2Znb2dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjg5MDMsImV4cCI6MjA4ODg0NDkwM30.N53hcpDdFXg07LsT8kjpoBIqN9v1DbDNEq7vMNw6K0s';
  
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  final seeder = DashboardVisualizationSeeder(supabase);
  await seeder.seedAll();
}
