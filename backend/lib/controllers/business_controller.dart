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

      // Notify Client
      try {
        final commandeData = await SupabaseConfig.client
            .from('commande')
            .select('id_client, client:id_client(id_user)')
            .eq('id_commande', int.parse(cid))
            .maybeSingle();

        if (commandeData != null) {
          final clientObj = commandeData['client'];
          final idUser = clientObj != null ? clientObj['id_user'] : null;
          if (idUser != null) {
            String statusMsg = 'Votre commande N°$cid est passée au statut : $statut';
            if (statut == 'confirmee') statusMsg = 'Votre commande N°$cid a été confirmée.';
            if (statut == 'en_preparation' || statut == 'preparee') statusMsg = 'Le restaurant prépare votre commande N°$cid.';
            if (statut == 'en_livraison') statusMsg = 'Votre commande N°$cid est en cours de livraison !';
            if (statut == 'livree') statusMsg = 'Votre commande N°$cid a été livrée. Bon appétit !';
            if (statut == 'annulee') statusMsg = 'Malheureusement, votre commande N°$cid a été annulée.';

            await _createNotification(idUser, 'Mise à jour de commande', statusMsg, 'commande');
          }
        }
      } catch (e) {
        print('Error notifying client on status update: $e');
      }

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

      // Fetch order lines containing these products to calculate stats
      final orderLines = await SupabaseConfig.client
          .from('ligne_commande')
          .select('id_commande, quantite, total_ligne, nom_snapshot, id_produit, commande(created_at)')
          .inFilter('id_produit', produitIds)
          .isFilter('deleted_at', null);

      double totalRevenu = 0;
      Set<int> uniqueOrders = {};
      Map<int, Map<String, dynamic>> productStats = {};
      
      List<double> chartData = List.filled(7, 0.0);
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);

      for (var line in orderLines) {
        final prixLigne = (line['total_ligne'] as num).toDouble();
        final qty = line['quantite'] as int;
        final pId = line['id_produit'] as int;
        final pName = line['nom_snapshot'] as String;

        totalRevenu += prixLigne;
        uniqueOrders.add(line['id_commande'] as int);

        if (!productStats.containsKey(pId)) {
          productStats[pId] = {'nom': pName, 'qte': 0, 'revenu': 0.0};
        }
        productStats[pId]!['qte'] += qty;
        productStats[pId]!['revenu'] += prixLigne;
        
        final commandeData = line['commande'];
        if (commandeData != null && commandeData is Map) {
          final createdAtStr = commandeData['created_at'];
          if (createdAtStr != null) {
            final date = DateTime.tryParse(createdAtStr.toString());
            if (date != null) {
              final dateDay = DateTime(date.year, date.month, date.day);
              final diff = todayDay.difference(dateDay).inDays;
              if (diff >= 0 && diff < 7) {
                chartData[6 - diff] += prixLigne;
              }
            }
          }
        }
      }

      // Sort Top Products by quantity
      var topProducts = productStats.values.toList();
      topProducts.sort((a, b) => (b['qte'] as int).compareTo(a['qte'] as int));
      topProducts = topProducts.take(5).toList();

      // Fetch recent orders (5 most recent)
      List<Map<String, dynamic>> recentOrders = [];
      if (uniqueOrders.isNotEmpty) {
        final orderIds = uniqueOrders.toList();
        final recentOrdersData = await SupabaseConfig.client
            .from('commande')
            .select('''
              id_commande,
              statut_commande,
              prix_total,
              created_at,
              client(
                id_client,
                app_user:id_user(nom, num_tl)
              )
            ''')
            .inFilter('id_commande', orderIds)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false)
            .limit(5);

        recentOrders = recentOrdersData.map((order) {
          final client = order['client'];
          final clientUser = client is Map ? client['app_user'] : null;
          return {
            'id_commande': order['id_commande'],
            'statut_commande': order['statut_commande'],
            'prix_total': order['prix_total'],
            'created_at': order['created_at'],
            'client_nom': clientUser?['nom'] ?? 'Client',
            'client_tel': clientUser?['num_tl'] ?? '',
          };
        }).toList();
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

      return Response.ok(
        jsonEncode({
          'data': {
            'revenus_totaux': totalRevenu,
            'nb_commandes': uniqueOrders.length,
            'note_moyenne': noteMoyenne.toStringAsFixed(1),
            'nb_produits': produits.length,
            'top_produits': topProducts,
            'chart_data': chartData,
            'recent_orders': recentOrders
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

  Future<void> _createNotification(dynamic idUser, String titre, String message, String type) async {
    try {
      final notif = await SupabaseConfig.client
          .from('notification')
          .insert({
            'titre': titre,
            'message': message,
            'type': type,
          })
          .select()
          .single();

      await SupabaseConfig.client.from('user_notification').insert({
        'id_user': idUser,
        'id_not': notif['id_not'] ?? notif['id'],
        'est_lu': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
}
