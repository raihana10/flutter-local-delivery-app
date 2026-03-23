import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class StatsController {
  final Map<String, String> _headers = {'content-type': 'application/json'};

  Future<Response> getRevenus(Request request) async {
    try {
      final params = request.url.queryParameters;

      var query = SupabaseConfig.client
          .from('commande')
          .select('prix_donne, type_commande, created_at')
          .eq('statut_commande', 'livree')
          .isFilter('deleted_at', null);

      if (params.containsKey('date_debut')) {
        query = query.gte('created_at', params['date_debut']!);
      }
      if (params.containsKey('date_fin')) {
        query = query.lte('created_at', params['date_fin']!);
      }

      final commandes = await query;

      double totalRevenu = 0.0;
      Map<String, double> parType = {};

      for (var cmd in commandes) {
        final prix = (cmd['prix_donne'] as num?)?.toDouble() ?? 0.0;
        final type = cmd['type_commande'] as String? ?? 'unknown';
        totalRevenu += prix;
        parType[type] = (parType[type] ?? 0.0) + prix;
      }

      return Response.ok(
        jsonEncode({
          'revenus_totaux': totalRevenu,
          'par_type': parType,
        }),
        headers: _headers,
      );
    } catch (e) {
      print('REVENUS ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }

  Future<Response> getLivreurStats(Request request) async {
    try {
      // Récupérer livreurs avec leurs infos
      final livreurs = await SupabaseConfig.client
          .from('livreur')
          .select('id_livreur, id_user, app_user:id_user(nom, email)')
          .isFilter('deleted_at', null);

      // Pour chaque livreur, compter ses courses livrées via timeline
      final List<Map<String, dynamic>> result = [];

      for (var livreur in livreurs) {
        final idLivreur = livreur['id_livreur'] as int;

        // Courses livrées
        final timelines = await SupabaseConfig.client
            .from('timeline')
            .select('id_commande, commande(statut_commande, frais_livraison)')
            .eq('id_livreur', idLivreur)
            .isFilter('deleted_at', null);

        int nbCourses = 0;
        double totalGains = 0.0;

        for (var t in timelines) {
          final cmd = t['commande'];
          if (cmd != null && cmd['statut_commande'] == 'livree') {
            nbCourses++;
            totalGains += ((cmd['frais_livraison'] as num?)?.toDouble() ?? 0.0) * 0.70;
          }
        }

        // Note moyenne depuis order_review
        final reviews = await SupabaseConfig.client
            .from('order_review')
            .select('evaluation')
            .inFilter('id_commande',
                timelines.map((t) => t['id_commande']).toList());

        double noteMoyenne = 0.0;
        if (reviews.isNotEmpty) {
          noteMoyenne = reviews.fold<double>(
                  0.0, (sum, r) => sum + (r['evaluation'] as num).toDouble()) /
              reviews.length;
        }

        final user = livreur['app_user'];
        result.add({
          'id_livreur': idLivreur,
          'nom': user?['nom'] ?? 'Livreur #$idLivreur',
          'email': user?['email'] ?? '',
          'nb_courses': nbCourses,
          'total_gains': totalGains,
          'note_moyenne': noteMoyenne,
        });
      }

      // Trier par nb_courses décroissant
      result.sort((a, b) =>
          (b['nb_courses'] as int).compareTo(a['nb_courses'] as int));

      return Response.ok(
        jsonEncode({'data': result}),
        headers: _headers,
      );
    } catch (e) {
      print('LIVREUR STATS ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }

  Future<Response> getBusinessStats(Request request) async {
    try {
      final businesses = await SupabaseConfig.client
          .from('business')
          .select('id_business, id_user, type_business, app_user:id_user(nom, email)')
          .isFilter('deleted_at', null);

      final List<Map<String, dynamic>> result = [];

      for (var business in businesses) {
        final idBusiness = business['id_business'] as int;

        // Produits du business
        final produits = await SupabaseConfig.client
            .from('produit')
            .select('id_produit')
            .eq('id_business', idBusiness)
            .isFilter('deleted_at', null);

        final produitIds = produits.map((p) => p['id_produit']).toList();

        double revenusTotaux = 0.0;
        int nbCommandes = 0;

        if (produitIds.isNotEmpty) {
          // Commandes livrées via ligne_commande
          final lignes = await SupabaseConfig.client
              .from('ligne_commande')
              .select('id_commande')
              .inFilter('id_produit', produitIds)
              .isFilter('deleted_at', null);

          final commandeIds = lignes.map((l) => l['id_commande']).toSet().toList();

          if (commandeIds.isNotEmpty) {
            final commandes = await SupabaseConfig.client
                .from('commande')
                .select('prix_total')
                .inFilter('id_commande', commandeIds)
                .eq('statut_commande', 'livree')
                .isFilter('deleted_at', null);

            nbCommandes = commandes.length;
            revenusTotaux = commandes.fold<double>(
                0.0,
                (sum, c) =>
                    sum + ((c['prix_total'] as num?)?.toDouble() ?? 0.0) * 0.75);
          }
        }

        // Note moyenne store_review
        final reviews = await SupabaseConfig.client
            .from('store_review')
            .select('evaluation')
            .eq('id_business', idBusiness)
            .isFilter('deleted_at', null);

        double noteMoyenne = 0.0;
        if (reviews.isNotEmpty) {
          noteMoyenne = reviews.fold<double>(
                  0.0, (sum, r) => sum + (r['evaluation'] as num).toDouble()) /
              reviews.length;
        }

        final user = business['app_user'];
        result.add({
          'id_business': idBusiness,
          'type_business': business['type_business'] ?? 'Autre',
          'nom': user?['nom'] ?? 'Business #$idBusiness',
          'email': user?['email'] ?? '',
          'nb_commandes': nbCommandes,
          'revenus_totaux': revenusTotaux,
          'note_moyenne': noteMoyenne,
        });
      }

      result.sort((a, b) =>
          (b['revenus_totaux'] as double).compareTo(a['revenus_totaux'] as double));

      return Response.ok(
        jsonEncode({'data': result}),
        headers: _headers,
      );
    } catch (e) {
      print('BUSINESS STATS ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }

  Future<Response> getPromotions(Request request) async {
    try {
      final now = DateTime.now().toIso8601String();
      final promos = await SupabaseConfig.client
          .from('promotion')
          .select('*, produit(nom_produit, business(app_user:id_user(nom)))')
          .lte('date_debut', now)
          .gte('date_fin', now)
          .isFilter('deleted_at', null);

      return Response.ok(
        jsonEncode({'data': promos}),
        headers: _headers,
      );
    } catch (e) {
      print('PROMOTIONS ERROR: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }
}
