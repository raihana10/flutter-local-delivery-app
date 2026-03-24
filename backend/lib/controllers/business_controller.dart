import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';

class BusinessController {
  final Map<String, String> _headers = {'content-type': 'application/json'};

  Future<Response> getBusinesses(Request request) async {
    try {
      final businesses = await SupabaseConfig.client
          .from('business')
          .select('*, app_user:id_user(nom, email, num_tl)')
          .isFilter('deleted_at', null);
      return Response.ok(jsonEncode({'data': businesses}), headers: _headers);
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> getBusinessDetail(Request request, String id) async {
    try {
      final business = await SupabaseConfig.client
          .from('business')
          .select('*, app_user:id_user(nom, email, num_tl)')
          .eq('id_business', int.parse(id))
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (business == null) {
        return Response(
          404,
          body: jsonEncode({'error': 'Not found'}),
          headers: _headers,
        );
      }
      return Response.ok(jsonEncode({'data': business}), headers: _headers);
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> getProduits(Request request, String id) async {
    try {
      final produits = await SupabaseConfig.client
          .from('produit')
          .select('*')
          .eq('id_business', int.parse(id))
          .isFilter('deleted_at', null);
      return Response.ok(jsonEncode({'data': produits}), headers: _headers);
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> addProduit(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      data['id_business'] = int.parse(id);

      final result = await SupabaseConfig.client
          .from('produit')
          .insert(data)
          .select()
          .single();

      return Response.ok(jsonEncode({'data': result}), headers: _headers);
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> updateProduit(Request request, String id, String pid) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final result = await SupabaseConfig.client
          .from('produit')
          .update(data)
          .eq('id_produit', int.parse(pid))
          .eq('id_business', int.parse(id))
          .select()
          .single();

      return Response.ok(jsonEncode({'data': result}), headers: _headers);
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> deleteProduit(Request request, String id, String pid) async {
    try {
      await SupabaseConfig.client
          .from('produit')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id_produit', int.parse(pid));
      return Response.ok(
        jsonEncode({'message': 'Deleted successfully'}),
        headers: _headers,
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> importProduitsCsv(Request request, String id) async {
    try {
      final payload = await request.readAsString();
      final lines = payload.split('\n');
      int inserted = 0;
      List<String> errors = [];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 4) {
          final nom = parts[0];
          final desc = parts[1];
          final prix = double.tryParse(parts[2]) ?? 0;
          final type = parts[3];

          try {
            await SupabaseConfig.client.from('produit').insert({
              'id_business': int.parse(id),
              'nom_produit': nom,
              'description': desc,
              'prix_unitaire': prix,
              'type_produit': type,
            });
            inserted++;
          } catch (e) {
            errors.add('Ligne $i : ${e.toString()}');
          }
        } else {
          errors.add('Ligne $i invalide format');
        }
      }
      return Response.ok(
        jsonEncode({'inserted': inserted, 'errors': errors}),
        headers: _headers,
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> getBusinessCommandes(Request request, String id) async {
    try {
      // Step 1 : get all produit ids for this business
      final produits = await SupabaseConfig.client
          .from('produit')
          .select('id_produit')
          .eq('id_business', int.parse(id))
          .isFilter('deleted_at', null);

      final produitIds = produits.map((p) => p['id_produit']).toList();

      if (produitIds.isEmpty) {
        return Response.ok(jsonEncode({'data': []}), headers: _headers);
      }

      // Step 2 : get all ligne_commande with those produit ids
      final lignes = await SupabaseConfig.client
          .from('ligne_commande')
          .select('id_commande')
          .inFilter('id_produit', produitIds)
          .isFilter('deleted_at', null);

      final commandeIds = lignes.map((l) => l['id_commande']).toSet().toList();

      if (commandeIds.isEmpty) {
        return Response.ok(jsonEncode({'data': []}), headers: _headers);
      }

      // Step 3 : get commandes with those ids
      final commandes = await SupabaseConfig.client
          .from('commande')
          .select('*, client(app_user:id_user(nom))')
          .inFilter('id_commande', commandeIds)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return Response.ok(jsonEncode({'data': commandes}), headers: _headers);
    } catch (e) {
      print('BUSINESS COMMANDES ERROR: $e');
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> updateCommandeStatut(
    Request request,
    String id,
    String cid,
  ) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final statut = data['statut'];

      await SupabaseConfig.client
          .from('commande')
          .update({'statut': statut, 'statut_commande': statut})
          .eq('id_commande', int.parse(cid));

      await SupabaseConfig.client
          .from('timeline')
          .update({'statut_tmlne': statut})
          .eq('id_commande', int.parse(cid));

      return Response.ok(
        jsonEncode({'message': 'Updated successfully'}),
        headers: _headers,
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> updateBusinessHours(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      await SupabaseConfig.client
          .from('business')
          .update({'opening_hours': data})
          .eq('id_business', int.parse(id));

      return Response.ok(
        jsonEncode({'message': 'Hours updated'}),
        headers: _headers,
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> getPromotions(Request request, String id) async {
    try {
      // Find products for this business
      final produits = await SupabaseConfig.client
          .from('produit')
          .select('id_produit, nom_produit')
          .eq('id_business', int.parse(id));

      final Map<int, String> pMap = {
        for (var item in (produits as List))
          item['id_produit'] as int: item['nom_produit'] as String,
      };

      if (pMap.isEmpty) {
        return Response.ok(jsonEncode({'data': []}), headers: _headers);
      }

      final promotions = await SupabaseConfig.client
          .from('promotion')
          .select('*')
          .inFilter('id_produit', pMap.keys.toList())
          .isFilter('deleted_at', null);

      final List results = (promotions as List).map((promo) {
        final p = Map<String, dynamic>.from(promo);
        p['nom_produit'] = pMap[p['id_produit']];
        return p;
      }).toList();

      return Response.ok(jsonEncode({'data': results}), headers: _headers);
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> createPromotion(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final result = await SupabaseConfig.client
          .from('promotion')
          .insert(data)
          .select()
          .single();

      return Response.ok(jsonEncode({'data': result}), headers: _headers);
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> deletePromotion(
    Request request,
    String id,
    String pid,
  ) async {
    try {
      await SupabaseConfig.client
          .from('promotion')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id_promotion', int.parse(pid));

      return Response.ok(
        jsonEncode({'message': 'Deleted successfully'}),
        headers: _headers,
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  Future<Response> getBusinessStats(Request request, String id) async {
    try {
      final businessId = int.parse(id);

      // Produits du business
      final produits = await SupabaseConfig.client
          .from('produit')
          .select('id_produit, nom_produit')
          .eq('id_business', businessId)
          .isFilter('deleted_at', null);

      final produitIds = produits.map((p) => p['id_produit']).toList();

      // Commandes livrées
      double revenusTotaux = 0.0;
      int nbCommandes = 0;
      Map<int, Map<String, dynamic>> topProduits = {};

      if (produitIds.isNotEmpty) {
        final lignes = await SupabaseConfig.client
            .from('ligne_commande')
            .select('id_commande, id_produit, quantite, total_ligne')
            .inFilter('id_produit', produitIds)
            .isFilter('deleted_at', null);

        final commandeIds = lignes.map((l) => l['id_commande']).toSet().toList();

        if (commandeIds.isNotEmpty) {
          final commandes = await SupabaseConfig.client
              .from('commande')
              .select('id_commande, prix_total')
              .inFilter('id_commande', commandeIds)
              .eq('statut_commande', 'livree')
              .isFilter('deleted_at', null);

          nbCommandes = commandes.length;
          for (var cmd in commandes) {
            revenusTotaux += ((cmd['prix_total'] as num).toDouble() * 0.75);
          }
        }

        // Top produits
        final Map<String, dynamic> produitNoms = {
          for (var p in produits)
            p['id_produit'].toString(): p['nom_produit'] as String
        };

        for (var ligne in lignes) {
          final pid = ligne['id_produit'] as int;
          if (!topProduits.containsKey(pid)) {
            topProduits[pid] = {
              'id_produit': pid,
              'nom_produit': produitNoms[pid.toString()] ?? 'Inconnu',
              'count': 0,
            };
          }
          topProduits[pid]!['count'] =
              (topProduits[pid]!['count'] as int) + (ligne['quantite'] as int);
        }
      }

      // Note moyenne
      double noteMoyenne = 0.0;
      final reviews = await SupabaseConfig.client
          .from('store_review')
          .select('evaluation')
          .eq('id_business', businessId)
          .isFilter('deleted_at', null);

      if (reviews.isNotEmpty) {
        final total = reviews.fold<double>(
            0.0, (sum, r) => sum + (r['evaluation'] as num).toDouble());
        noteMoyenne = total / reviews.length;
      }

      // Top 5 produits triés
      final top5 = topProduits.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return Response.ok(
        jsonEncode({
          'data': {
            'revenus_totaux': revenusTotaux,
            'nb_commandes': nbCommandes,
            'note_moyenne': noteMoyenne,
            'nb_produits': produits.length,
            'top_produits': top5.take(5).toList(),
          }
        }),
        headers: _headers,
      );
    } catch (e) {
      print('BUSINESS STATS ERROR: $e');
      return Response(500,
          body: jsonEncode({'error': e.toString()}), headers: _headers);
    }
  }
}
