import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class ClientOrdersController {
  
  // Create a new order (Checkout)
  Future<Response> createOrder(Request request) async {
    final userId = request.headers['x-client-id'];
    if (userId == null) return Response.forbidden('Missing client id');

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // Get id_client and name from user
      final clientRecord = await SupabaseConfig.client
          .from('client')
          .select('id_client, app_user:id_user(nom)')
          .eq('id_user', userId)
          .single();
      final idClient = clientRecord['id_client'];
      final clientNom = clientRecord['app_user']?['nom'] ?? 'Client';

      // Basic fields
      final idAdresse = data['id_adresse'];
      final typeCommande = data['type_commande'] ?? 'food_delivery';
      final cartItems = List<Map<String, dynamic>>.from(data['items'] ?? []);

      if (cartItems.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Cart is empty'}));
      }

      // 1. Calculate prices and build order line items
      double prixTotal = 0;
      final lignesAInserer = <Map<String, dynamic>>[];

      for (var item in cartItems) {
        final quantite = int.tryParse((item['quantity'] ?? item['quantite'] ?? 1).toString()) ?? 1;
        final prix = double.tryParse((item['price'] ?? item['prix_snapshot'] ?? 0).toString()) ?? 0.0;
        final nomSnapshot = (item['name'] ?? item['nom_snapshot'] ?? 'Produit Inconnu').toString();
        final idProduit = item['id_produit'] ?? item['id'];
        
        if (idProduit == null) {
          return Response(400, body: jsonEncode({'error': 'Missing id_produit in item: $item'}), headers: {'content-type': 'application/json'});
        }
        
        prixTotal += quantite * prix;
        lignesAInserer.add({
          'id_commande': 0, // will be filled after insert
          'id_produit': int.parse(idProduit.toString()),
          'quantite': quantite,
          'prix_snapshot': prix,
          'nom_snapshot': nomSnapshot,
        });
      }

      // Extract optional delivery info
      final distanceKm = data['distance_km'] != null ? double.tryParse(data['distance_km'].toString()) : null;
      
      // Fetch delivery rate from app_config
      double prixParKm = 1.5;
      try {
        final config = await SupabaseConfig.client
            .from('app_config')
            .select('valeur')
            .eq('cle', 'prix_par_km')
            .maybeSingle();
        if (config != null && config['valeur'] != null) {
          prixParKm = double.tryParse(config['valeur'].toString()) ?? 1.5;
        }
      } catch (e) {
        print('Error fetching app_config: $e');
      }

      double fraisLivraison = prixParKm; // Default for very short distance if needed
      if (distanceKm != null && distanceKm > 0) {
        double baseFee = distanceKm * prixParKm;
        double integerPart = baseFee.truncateToDouble();
        double fraction = baseFee - integerPart;
        
        if (fraction == 0) {
          fraisLivraison = baseFee;
        } else if (fraction <= 0.5) {
          fraisLivraison = integerPart + 0.5;
        } else {
          fraisLivraison = integerPart + 1.0;
        }
      }
      final totalAvecLivraison = prixTotal + fraisLivraison;

      // 2. Insert Commande
      final commande = await SupabaseConfig.client
          .from('commande')
          .insert({
            'id_client': idClient,
            'id_adresse': idAdresse,
            'type_commande': typeCommande,
            'statut_commande': 'confirmee',
            'prix_total': double.parse(totalAvecLivraison.toStringAsFixed(2)),
            'prix_donne': data['prix_donne'] ?? double.parse(totalAvecLivraison.toStringAsFixed(2)),
            if (distanceKm != null) 'distance_km': double.parse(distanceKm.toStringAsFixed(2)),
            'frais_livraison': double.parse(fraisLivraison.toStringAsFixed(2)),
          })
          .select()
          .single();

      final idCommande = commande['id_commande'] as int;

      // Fill in id_commande now that we have it
      for (var ligne in lignesAInserer) {
        ligne['id_commande'] = idCommande;
      }

      // 3. Insert Ligne Commandes
      await SupabaseConfig.client
          .from('ligne_commande')
          .insert(lignesAInserer);

      // 4. Create Timeline
      await SupabaseConfig.client
          .from('timeline')
          .insert({
            'id_commande': idCommande,
            'statut_tmlne': 'confirmee',
          });

      // 5. Notifications
      // Notify Client
      await _createNotification(int.parse(userId), 'Commande Confirmée', 'Votre commande N°$idCommande a été confirmée. Montant: ${totalAvecLivraison.toStringAsFixed(2)} DH (dont ${fraisLivraison.toStringAsFixed(2)} DH de livraison).', 'commande');

      // Notify Businesses
      try {
        final productIds = lignesAInserer.map((e) => e['id_produit']).toList();
        if (productIds.isNotEmpty) {
          final productsRes = await SupabaseConfig.client
              .from('produit')
              .select('id_produit, id_business, business(id_user)')
              .inFilter('id_produit', productIds);
          
          final businessUserIds = <int>{};
          for (var p in (productsRes as List)) {
            final b = p['business'];
            if (b != null && b['id_user'] != null) {
              businessUserIds.add(b['id_user'] as int);
            }
          }
          
          final itemsSummary = lignesAInserer.map((l) => '${l['quantite']}x ${l['nom_snapshot']}').join(', ');
          
          // Get address details for notification
          String adresseMsg = "";
          try {
             final adr = await SupabaseConfig.client.from('adresse').select('ville, details').eq('id_adresse', idAdresse).single();
             adresseMsg = "\n📍 Adresse: ${adr['ville']}, ${adr['details']}";
          } catch(e) { /* ignore */ }

          for (var bId in businessUserIds) {
            await _createNotification(bId, '🛒 Nouvelle Commande N°$idCommande', 'Client: $clientNom\nArticles: $itemsSummary\nTotal: ${totalAvecLivraison.toStringAsFixed(2)} DH$adresseMsg', 'commande');
          }
        }
      } catch (e) {
        print('Error notifying businesses: $e');
      }

      // Refetch whole order with details
      final fullOrder = await SupabaseConfig.client
          .from('commande')
          .select('*, ligne_commande(*), timeline(*)')
          .eq('id_commande', idCommande)
          .single();

      return Response.ok(jsonEncode({'success': true, 'data': fullOrder}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
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

  // Get current client's orders
  Future<Response> getMyOrders(Request request) async {
    final userId = request.headers['x-client-id'];
    if (userId == null) return Response.forbidden('Missing client id');

    try {
      final clientRecord = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', userId)
          .maybeSingle();
      
      if (clientRecord == null) {
        return Response.notFound(jsonEncode({'error': 'Client not found'}));
      }
      
      final idClient = clientRecord['id_client'];

      final orders = await SupabaseConfig.client
          .from('commande')
          .select('*, timeline(*), ligne_commande(*)')
          .eq('id_client', idClient)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return Response.ok(jsonEncode({'data': orders}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  // Get order timeline explicitly
  Future<Response> getOrderTimeline(Request request, String id) async {
    try {
      final timeline = await SupabaseConfig.client
          .from('timeline')
          .select()
          .eq('id_commande', id)
          .maybeSingle();

      if (timeline == null) return Response.notFound(jsonEncode({'error': 'Timeline not found'}));

      return Response.ok(jsonEncode({'data': timeline}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
