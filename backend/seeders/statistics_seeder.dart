import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

class StatisticsSeeder {
  final SupabaseClient _supabase;

  StatisticsSeeder(this._supabase);

  Future<void> seedAll() async {
    print('📊 Seeding statistics data...');
    
    await _seedWeeklyRevenueStats();
    await _seedTopLivreursStats();
    await _seedTopCommerceStats();
    
    print('✅ Statistics data seeded successfully!');
  }

  // Revenus générés (semaine actuelle) pour les statistiques
  Future<void> _seedWeeklyRevenueStats() async {
    print('💰 Seeding weekly revenue statistics...');
    
    final weeklyStats = {
      'current_week_revenue': 585000.75,
      'previous_week_revenue': 512300.25,
      'growth_percentage': 14.3,
      'daily_average': 83571.53,
      'best_day': 'Vendredi',
      'best_day_revenue': 125000.00,
      'transactions_count': 1247,
    };

    // Insérer dans Supabase
    await _supabase.from('stats_weekly_revenue').insert([weeklyStats]);

    print('✅ Weekly revenue statistics seeded');
  }

  // Top livreurs par performance
  Future<void> _seedTopLivreursStats() async {
    print('🏆 Seeding top livreurs statistics...');
    
    final topLivreurs = [
      {
        'id_user': 101,
        'nom': 'Karim Idrissi',
        'email': 'karim.idrissi@email.com',
        'deliveries_count': 156,
        'rating': 4.8,
        'total_revenue': 12480.00,
        'avg_delivery_time': 28, // minutes
        'completion_rate': 98.5,
      },
      {
        'id_user': 102,
        'nom': 'Fatima Zahra',
        'email': 'fatima.zahra@email.com',
        'deliveries_count': 142,
        'rating': 4.9,
        'total_revenue': 11360.00,
        'avg_delivery_time': 25,
        'completion_rate': 99.2,
      },
      {
        'id_user': 103,
        'nom': 'Mohammed Alaoui',
        'email': 'mohammed.alaoui@email.com',
        'deliveries_count': 128,
        'rating': 4.7,
        'total_revenue': 10240.00,
        'avg_delivery_time': 32,
        'completion_rate': 96.8,
      },
      {
        'id_user': 104,
        'nom': 'Aicha Bennani',
        'email': 'aicha.bennani@email.com',
        'deliveries_count': 115,
        'rating': 4.9,
        'total_revenue': 9200.00,
        'avg_delivery_time': 26,
        'completion_rate': 97.5,
      },
      {
        'id_user': 105,
        'nom': 'Youssef Tazi',
        'email': 'youssef.tazi@email.com',
        'deliveries_count': 98,
        'rating': 4.6,
        'total_revenue': 7840.00,
        'avg_delivery_time': 35,
        'completion_rate': 94.2,
      },
    ];

    // Insérer dans Supabase
    await _supabase.from('stats_top_livreurs').insert(topLivreurs);

    print('✅ Top livreurs statistics seeded: ${topLivreurs.length} livreurs');
  }

  // Top commerce/restaurants par performance
  Future<void> _seedTopCommerceStats() async {
    print('🏪 Seeding top commerce statistics...');
    
    final topCommerce = [
      {
        'id_user': 201,
        'nom': 'Supermarché Al-Mouna',
        'type': 'super-marche',
        'revenue': 45600.00,
        'orders_count': 234,
        'avg_order_value': 195.00,
        'rating': 4.7,
        'active_products': 1250,
      },
      {
        'id_user': 202,
        'nom': 'Restaurant Le Gourmet',
        'type': 'restaurant',
        'revenue': 38900.00,
        'orders_count': 189,
        'avg_order_value': 206.00,
        'rating': 4.8,
        'active_products': 85,
      },
      {
        'id_user': 203,
        'nom': 'Pharmacie Centrale',
        'type': 'pharmacie',
        'revenue': 32100.00,
        'orders_count': 156,
        'avg_order_value': 206.00,
        'rating': 4.9,
        'active_products': 450,
      },
      {
        'id_user': 204,
        'nom': 'Restaurant Casa Blanca',
        'type': 'restaurant',
        'revenue': 28700.00,
        'orders_count': 145,
        'avg_order_value': 198.00,
        'rating': 4.6,
        'active_products': 92,
      },
      {
        'id_user': 205,
        'nom': 'Supermarché Atlan',
        'type': 'super-marche',
        'revenue': 25400.00,
        'orders_count': 128,
        'avg_order_value': 198.00,
        'rating': 4.5,
        'active_products': 980,
      },
      {
        'id_user': 206,
        'nom': 'Pharmacie du Sud',
        'type': 'pharmacie',
        'revenue': 22100.00,
        'orders_count': 98,
        'avg_order_value': 225.00,
        'rating': 4.7,
        'active_products': 320,
      },
      {
        'id_user': 207,
        'nom': 'Restaurant Pizza Express',
        'type': 'restaurant',
        'revenue': 19800.00,
        'orders_count': 87,
        'avg_order_value': 228.00,
        'rating': 4.4,
        'active_products': 45,
      },
    ];

    // Insérer dans Supabase
    await _supabase.from('stats_top_commerce').insert(topCommerce);

    print('✅ Top commerce statistics seeded: ${topCommerce.length} commerce');
  }
}

void main() async {
  print('🔌 Loading environment variables...');
  
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final supabaseUrl = env['SUPABASE_URL'] ?? 'https://tyaljeydufvvcbkfgogg.supabase.co';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWxqZXlkdWZ2dmNia2Znb2dnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyNjg5MDMsImV4cCI6MjA4ODg0NDkwM30.N53hcpDdFXg07LsT8kjpoBIqN9v1DbDNEq7vMNw6K0s';

  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final seeder = StatisticsSeeder(supabase);
  await seeder.seedAll();
}
