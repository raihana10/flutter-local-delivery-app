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

      // Get id_client from user
      final clientRecord = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', userId)
          .single();
      final idClient = clientRecord['id_client'];

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

      // 2. Insert Commande
      final commande = await SupabaseConfig.client
          .from('commande')
          .insert({
            'id_client': idClient,
            'id_adresse': idAdresse,
            'type_commande': typeCommande,
            'statut_commande': 'confirmee',
            'prix_total': prixTotal,
            'prix_donne': prixTotal,
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
