import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';
import '../core/commission_config.dart';

class PaiementsController {
  Future<Response> getPaiements(Request request) async {
    try {
      final params = request.url.queryParameters;
      var query = SupabaseConfig.client
          .from('commande')
          .select('*, client(id_client, id_user(nom))')
          .isFilter('deleted_at', null);

      if (params.containsKey('statut')) {
        query = query.eq('statut_commande', params['statut']!);
      }
      if (params.containsKey('date_debut')) {
        query = query.gte('date', params['date_debut']!);
      }
      if (params.containsKey('date_fin')) {
        query = query.lte('date', params['date_fin']!);
      }

      final commandes = await query;
      return Response.ok(
        jsonEncode({'data': commandes}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('PAIEMENTS ERROR: $e');
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getCommissions(Request request) async {
    try {
      final commandes = await SupabaseConfig.client
          .from('commande')
          .select('*')
          .eq('statut_commande', 'livree')
          .isFilter('deleted_at', null);

      double revenusAppTotal = 0.0;
      double revenusLivreurTotal = 0.0;
      double revenusBusinessTotal = 0.0;

      List<Map<String, dynamic>> detail = [];

      for (var cmd in commandes) {
        final prixProduits = (cmd['prix_total'] as num).toDouble();
        final fraisLivraison = (cmd['frais_livraison'] as num).toDouble();

        final commissionBusiness =
            prixProduits * CommissionConfig.commissionBusinessRate;
        final revenusBusiness = prixProduits * CommissionConfig.businessRate;
        final revenusLivreur = fraisLivraison * CommissionConfig.livreurRate;
        final revenusApp =
            commissionBusiness +
            (fraisLivraison * CommissionConfig.appLivraisonRate);

        revenusAppTotal += revenusApp;
        revenusLivreurTotal += revenusLivreur;
        revenusBusinessTotal += revenusBusiness;

        detail.add({
          'id_commande': cmd['id_commande'],
          'prix_total': prixProduits,
          'frais_livraison': fraisLivraison,
          'distance_km': cmd['distance_km'] ?? 0,
          'revenus_app': revenusApp,
          'revenus_livreur': revenusLivreur,
          'revenus_business': revenusBusiness,
        });
      }

      final result = {
        'revenus_app_total': revenusAppTotal,
        'revenus_livreurs_total': revenusLivreurTotal,
        'revenus_businesses_total': revenusBusinessTotal,
        'detail': detail,
      };

      return Response.ok(
        jsonEncode({'data': result}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('COMMISSIONS ERROR: $e');
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getLivreurEarnings(Request request, String id) async {
    try {
      // ✅ Chercher dans timeline les commandes assignées à ce livreur
      final timelines = await SupabaseConfig.client
          .from('timeline')
          .select('id_commande, commande(prix_total, frais_livraison, statut_commande, prix_donne)')
          .eq('id_livreur', int.parse(id))
          .isFilter('deleted_at', null);

      int nbCourses = 0;
      double totalGains = 0.0;

      for (var t in timelines) {
        final cmd = t['commande'];
        if (cmd == null) continue;
        if (cmd['statut_commande'] == 'livree') {
          nbCourses++;
          final frais = (cmd['frais_livraison'] as num?)?.toDouble() ?? 0.0;
          totalGains += frais * 0.70; // livreur reçoit 70%
        }
      }

      return Response.ok(
        jsonEncode({
          'id_livreur': int.parse(id),
          'nb_courses': nbCourses,
          'total_gains': totalGains,
          'detail': timelines,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('LIVREUR GAINS ERROR: $e');
      return Response(500,
          body: jsonEncode({'error': e.toString()}),
          headers: {'content-type': 'application/json'});
    }
  }
}
