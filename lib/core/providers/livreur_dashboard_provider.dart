import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/models/commande_supabase_model.dart';
import 'package:app/core/providers/auth_provider.dart';

class LivreurDashboardProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthProvider _authProvider;

  bool _isOnline = false;
  bool _isOnMission = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommandeSupabaseModel> _availableCommandes = [];
  CommandeSupabaseModel? _activeCommande;
  StreamSubscription? _commandesSubscription;

  LivreurDashboardProvider(this._authProvider) {
    // If the user logs out, clean up
    _authProvider.addListener(_onAuthChanged);
  }

  bool get isOnline => _isOnline;
  bool get isOnMission => _isOnMission;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CommandeSupabaseModel> get availableCommandes => _availableCommandes;
  CommandeSupabaseModel? get activeCommande => _activeCommande;

  void _onAuthChanged() {
    if (!_authProvider.isAuthenticated) {
      _isOnline = false;
      _isOnMission = false;
      _activeCommande = null;
      _stopListeningToCommandes();
      notifyListeners();
    }
  }

  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    if (_isOnline) {
      _startListeningToCommandes();
    } else {
      _stopListeningToCommandes();
    }
    notifyListeners();
  }

  void _startListeningToCommandes() {
    _stopListeningToCommandes();
    
    // Listen to commandes that are confirmed or prepared
    _commandesSubscription = _supabase
        .from('commande')
        .stream(primaryKey: ['id_commande'])
        .eq('statut_commande', 'confirmee') // Also could listen to 'preparee'
        .listen((data) async {
          if (!_isOnline || _isOnMission) return;
          
          _availableCommandes.clear();
          
          for (var item in data) {
            // Need to fetch joined data (adresse, client phone)
            try {
              final response = await _supabase
                  .from('commande')
                  .select('''
                    *,
                    adresse (*),
                    client (
                      app_user (num_tl)
                    ),
                    ligne_commande (
                      quantite,
                      nom_snapshot,
                      prix_snapshot
                    )
                  ''')
                  .eq('id_commande', item['id_commande'])
                  .single();
                  
              _availableCommandes.add(CommandeSupabaseModel.fromJson(response));
            } catch (e) {
              debugPrint('Error fetching joined data for order ${item['id_commande']}: $e');
            }
          }
          notifyListeners();
        });
  }

  void _stopListeningToCommandes() {
    _commandesSubscription?.cancel();
    _commandesSubscription = null;
    _availableCommandes.clear();
  }

  Future<bool> accepterCommande(CommandeSupabaseModel commande) async {
    _setLoading(true);
    _clearError();

    try {
      final userId = _authProvider.user?.id; // This is app_user.id_user
      if (userId == null) throw Exception("Utilisateur non connecté");

      // 1. Get the livreur ID associated with this app_user
      final livreurRes = await _supabase
          .from('livreur')
          .select('id_livreur')
          .eq('id_user', userId)
          .single();
          
      final int idLivreur = livreurRes['id_livreur'];

      // 2. Try to assign the order in the timeline
      // Using upsert or insert depending on if timeline exists
      final timelineRes = await _supabase.from('timeline').select('id_timeline').eq('id_commande', commande.idCommande).maybeSingle();
      
      if (timelineRes == null) {
          await _supabase.from('timeline').insert({
            'id_commande': commande.idCommande,
            'id_livreur': idLivreur,
            'statut_tmlne': 'en_livraison'
          });
      } else {
          // If a timeline exists, check if it already has a livreur
          final existingTimeline = await _supabase.from('timeline').select('id_livreur').eq('id_commande', commande.idCommande).single();
          if (existingTimeline['id_livreur'] != null) {
              throw Exception("Commande déjà acceptée par un autre livreur");
          }
          
          await _supabase.from('timeline').update({
            'id_livreur': idLivreur,
            'statut_tmlne': 'en_livraison'
          }).eq('id_commande', commande.idCommande);
      }

      // 3. Update the commande status
      await _supabase.from('commande').update({
        'statut_commande': 'en_livraison'
      }).eq('id_commande', commande.idCommande);

      _activeCommande = commande;
      _isOnMission = true;
      _stopListeningToCommandes();
      
      _setLoading(false);
      return true;

    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> terminerLivraison() async {
     _setLoading(true);
     _clearError();
     
     if (_activeCommande == null) {
        _setLoading(false);
        return false;
     }

     try {
       // Update commande
       await _supabase.from('commande').update({
         'statut_commande': 'livree'
       }).eq('id_commande', _activeCommande!.idCommande);
       
       // Update timeline
       await _supabase.from('timeline').update({
         'statut_tmlne': 'livree'
       }).eq('id_commande', _activeCommande!.idCommande);

       _activeCommande = null;
       _isOnMission = false;
       if (_isOnline) {
          _startListeningToCommandes();
       }
       
       _setLoading(false);
       return true;
     } catch (e) {
        _setError(e.toString());
        _setLoading(false);
        return false;
     }
  }

  Future<List<CommandeSupabaseModel>> fetchHistorique() async {
    try {
      final userId = _authProvider.user?.id;
      if (userId == null) return [];

      final livreurRes = await _supabase
          .from('livreur')
          .select('id_livreur')
          .eq('id_user', userId)
          .maybeSingle();
      
      if (livreurRes == null) return [];
      final int idLivreur = livreurRes['id_livreur'];

      // Fetch livree commandes for this livreur
      final response = await _supabase
          .from('commande')
          .select('''
            *,
            adresse (*),
            client (
              app_user (num_tl)
            ),
            ligne_commande (
              quantite,
              nom_snapshot,
              prix_snapshot
            ),
            timeline!inner (
              id_livreur,
              statut_tmlne
            )
          ''')
          .eq('statut_commande', 'livree')
          .eq('timeline.id_livreur', idLivreur)
          .order('updated_at', ascending: false);

      return (response as List).map((e) => CommandeSupabaseModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching historique: $e');
      return [];
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopListeningToCommandes();
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
