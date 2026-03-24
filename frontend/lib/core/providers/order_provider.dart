
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/commande_model.dart';

class OrderProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _orderHistory = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get orderHistory => _orderHistory;

  Future<void> fetchOrderHistory(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('commande')
          .select('''
            id_commande,
            prix_total,
            created_at,
            statut_commande,
            ligne_commande (
              id_produit,
              quantite,
              nom_snapshot,
              prix_snapshot,
              produit (
                nom_produit,
                image,
                business (
                  id_business,
                  app_user (nom)
                )
              )
            )
          ''')
          .eq('id_client', clientId)
          .order('created_at', ascending: false);

      _orderHistory = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching order history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Temporary mock acceptor if real data is missing, for demonstration
  Future<void> createMockOrder(int clientId) async {
    try {
      await _supabase.from('commande').insert({
        'id_client': clientId,
        'id_adresse': null, // Need an address ID if foreign key exists, check schema
        'id_livreur': null,
        'statut_commande': 'livree',
        'prix_total': 150.0,
        'moyen_paiement': 'cash',
        'created_at': DateTime.now().toIso8601String(),
      });
      await fetchOrderHistory(clientId);
    } catch (e) {
      debugPrint('Error creating mock order: $e');
    }
  }
}
