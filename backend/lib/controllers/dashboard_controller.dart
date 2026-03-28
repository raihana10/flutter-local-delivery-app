import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class DashboardController {
  final Map<String, String> _headers = {'content-type': 'application/json'};

  Future<Response> getKPIs(Request request) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      final activeOrdersRes = await SupabaseConfig.client
          .from('commande')
          .select('id_commande')
          .inFilter('statut_commande', ['confirmee', 'preparee', 'en_livraison'])
          .isFilter('deleted_at', null);

      final revenueRes = await SupabaseConfig.client
          .from('commande')
          .select('prix_donne')
          .gte('created_at', todayStart)
          .eq('statut_commande', 'livree')
          .isFilter('deleted_at', null);

      double dailyRevenue = 0.0;
      for (var row in revenueRes) {
        dailyRevenue += ((row['prix_donne'] as num?)?.toDouble() ?? 0.0);
      }

      final activeDriversRes = await SupabaseConfig.client
          .from('livreur')
          .select('id_livreur')
          .eq('est_actif', true)
          .isFilter('deleted_at', null);

      final newUsersRes = await SupabaseConfig.client
          .from('app_user')
          .select('id_user')
          .gte('created_at', todayStart)
          .isFilter('deleted_at', null);

      return Response.ok(
        jsonEncode({
          'commandes_actives': activeOrdersRes.length,
          'revenus_jour': dailyRevenue,
          'livreurs_actifs': activeDriversRes.length,
          'nouveaux_users': newUsersRes.length,
        }),
        headers: _headers,
      );
    } catch (e) {
      print('KPIs ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }

  Future<Response> getChartData(Request request) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // ✅ Vraies colonnes : prix_donne, statut_commande
      final orders = await SupabaseConfig.client
          .from('commande')
          .select('created_at, prix_donne, statut_commande')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .isFilter('deleted_at', null)
          .order('created_at');

      // 1. Revenus par jour (7 derniers jours)
      final List<String> weekDays = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
      Map<String, double> dailyRevenue = {};

      for (var order in orders) {
        if (order['statut_commande'] == 'livree') {
          final day = (order['created_at'] as String).substring(0, 10);
          dailyRevenue[day] = (dailyRevenue[day] ?? 0) +
              ((order['prix_donne'] as num?)?.toDouble() ?? 0.0);
        }
      }

      List<Map<String, dynamic>> revenueList = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = date.toIso8601String().substring(0, 10);
        revenueList.add({
          'day': weekDays[date.weekday % 7],
          'date': dateStr,
          'revenue': dailyRevenue[dateStr] ?? 0.0,
        });
      }

      // 2. Statuts des commandes — ✅ valeurs exactes de l'enum
      final Map<String, int> statusCounts = {
        'confirmee': 0,
        'preparee': 0,
        'en_livraison': 0,
        'livree': 0,
      };
      final Map<String, int> statusColors = {
        'confirmee': 0xFFFFA726,
        'preparee': 0xFF42A5F5,
        'en_livraison': 0xFF66BB6A,
        'livree': 0xFF26A69A,
      };
      final Map<String, String> statusLabels = {
        'confirmee': 'Confirmée',
        'preparee': 'Préparée',
        'en_livraison': 'En livraison',
        'livree': 'Livrée',
      };

      for (var order in orders) {
        final status = order['statut_commande'] as String? ?? '';
        if (statusCounts.containsKey(status)) {
          statusCounts[status] = statusCounts[status]! + 1;
        }
      }

      final statusList = statusCounts.entries.map((entry) => {
        'status': statusLabels[entry.key] ?? entry.key,
        'count': entry.value,
        'color': statusColors[entry.key] ?? 0xFFFFA726,
      }).toList();

      return Response.ok(
        jsonEncode({
          'weeklyRevenue': revenueList,
          'ordersByStatus': statusList,
        }),
        headers: _headers,
      );
    } catch (e) {
      print('CHART DATA ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }

  Future<Response> getAlerts(Request request) async {
    try {
      // Livreurs en attente de validation (est_actif=false) avec infos user
      final pendingLivreurs = await SupabaseConfig.client
          .from('livreur')
          .select('id_user, app_user:id_user(nom, email)')
          .eq('est_actif', false)
          .isFilter('deleted_at', null);

      // Businesses en attente de validation (est_actif=false) avec infos user
      final pendingBusinesses = await SupabaseConfig.client
          .from('business')
          .select('id_user, app_user:id_user(nom, email)')
          .eq('est_actif', false)
          .isFilter('deleted_at', null);

      // Normaliser : ajouter role et aplatir les infos app_user
      final formattedPending = [
        ...(pendingLivreurs as List).map((item) {
          final userInfo = item['app_user'];
          return {
            'id_user': item['id_user'],
            'nom': userInfo != null ? (userInfo['nom'] ?? 'Sans nom') : 'Sans nom',
            'email': userInfo != null ? (userInfo['email'] ?? '') : '',
            'role': 'livreur',
          };
        }),
        ...(pendingBusinesses as List).map((item) {
          final userInfo = item['app_user'];
          return {
            'id_user': item['id_user'],
            'nom': userInfo != null ? (userInfo['nom'] ?? 'Sans nom') : 'Sans nom',
            'email': userInfo != null ? (userInfo['email'] ?? '') : '',
            'role': 'business',
          };
        }),
      ];

      final thirtyMinsAgo = DateTime.now()
          .subtract(const Duration(minutes: 30))
          .toIso8601String();

      final blockedOrders = await SupabaseConfig.client
          .from('commande')
          .select('id_commande, statut_commande, created_at')
          .eq('statut_commande', 'confirmee')
          .lte('created_at', thirtyMinsAgo)
          .isFilter('deleted_at', null);

      // Ajouter blocked_since pour chaque commande bloquée
      final formattedBlocked = (blockedOrders as List).map((order) {
        final createdAt = DateTime.parse(order['created_at'] as String);
        final diff = DateTime.now().difference(createdAt);
        return {
          ...Map<String, dynamic>.from(order),
          'blocked_since': '${diff.inMinutes} min',
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          'pending_validations': formattedPending,
          'blocked_orders': formattedBlocked,
        }),
        headers: _headers,
      );
    } catch (e) {
      print('ALERTS ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }

  Future<Response> getLiveDrivers(Request request) async {
    try {
      final liveDrivers = await SupabaseConfig.client
          .from('timeline')
          .select('id_livreur, position_order, statut_tmlne, livreur(id_livreur, app_user:id_user(nom))')
          .eq('statut_tmlne', 'en_livraison')
          .isFilter('deleted_at', null);

      final formatted = (liveDrivers as List).map((d) {
        final livreur = d['livreur'];
        final user = livreur != null ? livreur['app_user'] : null;
        return {
          'id_livreur': d['id_livreur'],
          'position_order': d['position_order'],
          'statut_tmlne': d['statut_tmlne'],
          'nom': user?['nom'] ?? 'Livreur #${d['id_livreur']}',
          'status': 'en_mission',
        };
      }).toList();

      return Response.ok(
        jsonEncode({'data': formatted}),
        headers: _headers,
      );
    } catch (e) {
      print('LIVE DRIVERS ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }
}
