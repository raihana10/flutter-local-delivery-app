import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class CommandesController {
  final Map<String, String> _headers = {'content-type': 'application/json'};

  static const String _commandeSelect = '''
    *,
    client(
      id_client,
      app_user:id_user(nom, email, num_tl)
    ),
    adresse(ville, latitude, longitude),
    timeline(
      id_livreur,
      statut_tmlne,
      estimated_at,
      remaining_time,
      remaining_distance,
      position_order,
      livreur(
        id_livreur,
        app_user:id_user(nom, num_tl)
      )
    ),
    ligne_commande(
      id_lc,
      quantite,
      prix_snapshot,
      nom_snapshot,
      total_ligne,
      produit(
        id_produit,
        nom_produit,
        id_business,
        business(
          id_business,
          app_user:id_user(nom)
        )
      )
    )
  ''';

  Map<String, dynamic> _flattenCommande(Map<String, dynamic> cmd) {
    final map = Map<String, dynamic>.from(cmd);

    // Extraire nom client
    final client = map['client'];
    final clientUser = client is Map ? client['app_user'] : null;
    map['client_nom'] = clientUser?['nom'] ?? 'Client #${map['id_client']}';
    map['client_tel'] = clientUser?['num_tl'] ?? '';

    // Extraire livreur depuis timeline
    final timeline = map['timeline'];
    final timelineData = timeline is List && timeline.isNotEmpty
        ? timeline[0]
        : (timeline is Map ? timeline : null);
    final livreurData = timelineData?['livreur'];
    final livreurUser = livreurData is Map ? livreurData['app_user'] : null;
    map['livreur_nom'] = livreurUser?['nom'];
    map['livreur_tel'] = livreurUser?['num_tl'];
    map['id_livreur'] = timelineData?['id_livreur'];

    // Extraire business depuis ligne_commande → produit → business
    final lignes = map['ligne_commande'];
    if (lignes is List && lignes.isNotEmpty) {
      final premierProduit = lignes[0]['produit'];
      final business = premierProduit is Map ? premierProduit['business'] : null;
      final businessUser = business is Map ? business['app_user'] : null;
      map['business_nom'] = businessUser?['nom'] ?? 'Business #${premierProduit?['id_business']}';
      map['id_business'] = premierProduit?['id_business'];
    } else {
      map['business_nom'] = 'Non défini';
      map['id_business'] = null;
    }

    return map;
  }

  Future<Response> getCommandes(Request request) async {
    try {
      final params = request.url.queryParameters;

      // ✅ Filtres AVANT order
      var query = SupabaseConfig.client
          .from('commande')
          .select(_commandeSelect)
          .isFilter('deleted_at', null);

      if (params.containsKey('statut')) {
        query = query.eq('statut_commande', params['statut']!);
      }
      if (params.containsKey('type_commande')) {
        query = query.eq('type_commande', params['type_commande']!);
      }
      if (params.containsKey('date_debut')) {
        query = query.gte('created_at', params['date_debut']!);
      }
      if (params.containsKey('date_fin')) {
        query = query.lte('created_at', params['date_fin']!);
      }

      // ✅ order EN DERNIER
      final commandes = await query.order('created_at', ascending: false);

      final formatted = (commandes as List)
          .map((cmd) => _flattenCommande(Map<String, dynamic>.from(cmd)))
          .toList();

      return Response.ok(
        jsonEncode({'data': formatted}),
        headers: _headers,
      );
    } catch (e) {
      print('COMMANDES ERROR: $e');
      return Response(500,
          body: jsonEncode({'error': e.toString()}),
          headers: _headers);
    }
  }

  Future<Response> getCommandeDetail(Request request, String id) async {
    try {
      final commande = await SupabaseConfig.client
          .from('commande')
          .select(_commandeSelect)
          .eq('id_commande', int.parse(id))
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (commande == null) {
        return Response(404,
            body: jsonEncode({'error': 'Commande not found'}),
            headers: _headers);
      }

      final formatted = _flattenCommande(Map<String, dynamic>.from(commande));

      return Response.ok(
          jsonEncode({'data': formatted}),
          headers: _headers);
    } catch (e) {
      print('COMMANDE DETAIL ERROR: $e');
      return Response(500,
          body: jsonEncode({'error': e.toString()}),
          headers: _headers);
    }
  }

  Future<Response> rembourseCommande(Request request, String id) async {
    try {
      final updatedCommande = await SupabaseConfig.client
          .from('commande')
          .update({'prix_donne': 0.0})
          .eq('id_commande', int.parse(id))
          .isFilter('deleted_at', null)
          .select();

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Remboursement effectué',
          'data': updatedCommande,
        }),
        headers: _headers,
      );
    } catch (e) {
      print('REMBOURSEMENT ERROR: $e');
      return Response(500,
          body: jsonEncode({'error': e.toString()}),
          headers: _headers);
    }
  }
}