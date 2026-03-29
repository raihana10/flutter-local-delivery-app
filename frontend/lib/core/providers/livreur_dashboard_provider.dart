import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/models/commande_supabase_model.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/data/models/gains_model.dart' as app_models;

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
  Timer? _pollingTimer;
  final Set<int> _ignoredCommandes = {};

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

  void ignorerCommande(int idCommande) {
    _ignoredCommandes.add(idCommande);
    _availableCommandes.removeWhere((c) => c.idCommande == idCommande);
    notifyListeners();
  }

  void _startListeningToCommandes() {
    _stopListeningToCommandes();
    _fetchAvailableCommandes();
    _pollingTimer = Timer.periodic(const Duration(seconds: 7), (_) => _fetchAvailableCommandes());
  }

  Future<void> _fetchAvailableCommandes() async {
    if (!_isOnline || _isOnMission) return;

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}

    try {
      final response = await _supabase.from('commande').select('''
            *,
            adresse (*),
            client (
              app_user (num_tl, nom)
            ),
            ligne_commande (
              quantite,
              nom_snapshot,
              prix_snapshot,
              produit (
                business (
                  app_user (
                    nom,
                    user_adresse (
                      adresse (latitude, longitude)
                    )
                  )
                )
              )
            ),
            timeline (
              id_livreur
            )
          ''').inFilter('statut_commande', const ['confirmee', 'preparee']);

      List<CommandeSupabaseModel> fetched = [];

      for (var item in (response as List)) {
        if (_ignoredCommandes.contains(item['id_commande'])) continue;

        // Check timeline if someone claimed it
        bool claimed = false;
        if (item['timeline'] != null) {
           final timelines = item['timeline'] is List ? item['timeline'] as List : [item['timeline']];
           for (var tl in timelines) {
             if (tl['id_livreur'] != null) {
               claimed = true;
               break;
             }
           }
        }
        if (claimed) continue;

        fetched.add(CommandeSupabaseModel.fromJson(item, driverLat: pos?.latitude, driverLng: pos?.longitude));
      }

      fetched.sort((a, b) => a.distance.compareTo(b.distance));
      
      _availableCommandes = fetched;
      notifyListeners();

    } catch (e) {
      debugPrint('Error fetching available commandes: $e');
    }
  }

  void _stopListeningToCommandes() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
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
      final timelineRes = await _supabase
          .from('timeline')
          .select('id_timeline')
          .eq('id_commande', commande.idCommande)
          .maybeSingle();

      if (timelineRes == null) {
        await _supabase.from('timeline').insert({
          'id_commande': commande.idCommande,
          'id_livreur': idLivreur,
          'statut_tmlne': 'en_livraison'
        });
      } else {
        // If a timeline exists, check if it already has a livreur
        final existingTimeline = await _supabase
            .from('timeline')
            .select('id_livreur')
            .eq('id_commande', commande.idCommande)
            .single();
        if (existingTimeline['id_livreur'] != null) {
          throw Exception("Commande déjà acceptée par un autre livreur");
        }

        await _supabase.from('timeline').update({
          'id_livreur': idLivreur,
          'statut_tmlne': 'en_livraison'
        }).eq('id_commande', commande.idCommande);
      }

      // 3. Update the commande status
      await _supabase
          .from('commande')
          .update({'statut_commande': 'en_livraison'}).eq(
              'id_commande', commande.idCommande);

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

  Future<bool> confirmerPriseEnCharge() async {
    _setLoading(true);
    _clearError();

    if (_activeCommande == null) {
      _setLoading(false);
      return false;
    }

    try {
      // Update commande status
      await _supabase
          .from('commande')
          .update({'statut_commande': 'en_livraison'})
          .eq('id_commande', _activeCommande!.idCommande);

      // Create business address location map
      final businessPos = _activeCommande!.latRestaurant != null && _activeCommande!.lngRestaurant != null 
          ? {'latitude': _activeCommande!.latRestaurant, 'longitude': _activeCommande!.lngRestaurant}
          : null;

      final Map<String, dynamic> timelineUpdate = {'statut_tmlne': 'en_livraison'};
      if (businessPos != null) {
        timelineUpdate['position_order'] = businessPos;
      }

      // Update timeline status
      await _supabase
          .from('timeline')
          .update(timelineUpdate)
          .eq('id_commande', _activeCommande!.idCommande);

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
      await _supabase.from('commande').update({'statut_commande': 'livree'}).eq(
          'id_commande', _activeCommande!.idCommande);

      // Create client address location map
      final clientPos = _activeCommande!.latClient != null && _activeCommande!.lngClient != null 
          ? {'latitude': _activeCommande!.latClient, 'longitude': _activeCommande!.lngClient}
          : null;

      final Map<String, dynamic> timelineUpdate = {'statut_tmlne': 'livree'};
      if (clientPos != null) {
        timelineUpdate['position_order'] = clientPos;
      }

      // Update timeline
      await _supabase.from('timeline').update(timelineUpdate).eq(
          'id_commande', _activeCommande!.idCommande);

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
              app_user (num_tl, nom)
            ),
            ligne_commande (
              quantite,
              nom_snapshot,
              prix_snapshot,
              produit (
                business (
                  app_user (
                    nom,
                    user_adresse (
                      adresse (latitude, longitude)
                    )
                  )
                )
              )
            ),
            timeline!inner (
              id_livreur,
              statut_tmlne
            )
          ''')
          .eq('statut_commande', 'livree')
          .eq('timeline.id_livreur', idLivreur)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((e) => CommandeSupabaseModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching historique: $e');
      return [];
    }
  }

  Future<app_models.GainsModel?> fetchGains() async {
    try {
      final userId = _authProvider.user?.id;
      if (userId == null) return null;

      final livreurRes = await _supabase
          .from('livreur')
          .select('id_livreur')
          .eq('id_user', userId)
          .maybeSingle();

      if (livreurRes == null) return null;
      final int idLivreur = livreurRes['id_livreur'];

      // Fetch lifetime stats
      final lifetimeRes = await _supabase
          .from('commande')
          .select('''
            id_commande,
            prix_total,
            frais_livraison,
            type_commande,
            distance_km,
            updated_at,
            timeline!inner (id_livreur)
          ''')
          .eq('statut_commande', 'livree')
          .eq('timeline.id_livreur', idLivreur)
          .order('updated_at', ascending: false);
      
      int totalLivraisons = lifetimeRes.length;
      double totalDistance = 0.0;
      double aujourdhui = 0;
      double semaine = 0;
      List<double> parJour = List.filled(7, 0.0);
      Map<String, int> repartitionType = {'food_delivery': 0, 'shopping': 0};
      List<app_models.LivraisonRecente> recentes = [];

      final now = DateTime.now();

      for (var row in lifetimeRes) {
        final distStr = row['distance_km']?.toString() ?? '0';
        totalDistance += double.tryParse(distStr) ?? 0.0;

        // we use frais_livraison as the Livreur's earnings
        final montantStr = row['frais_livraison']?.toString() ?? '0';
        final montant = double.tryParse(montantStr) ?? 0.0;
        
        final dtStr = row['updated_at']?.toString() ?? now.toIso8601String();
        // Parse dt as UTC and convert to local manually for safer calculation
         DateTime? dtParsed = DateTime.tryParse(dtStr);
         if (dtParsed != null && !dtStr.endsWith('Z') && !dtStr.contains('+')) {
            dtParsed = DateTime.tryParse('${dtStr}Z');
         }
        final dt = (dtParsed ?? now).toLocal();
        
        final typeStr = row['type_commande']?.toString() ?? 'food_delivery';

        // Repartition
        repartitionType[typeStr] = (repartitionType[typeStr] ?? 0) + 1;

        // Livraisons recentes (max 5)
        if (recentes.length < 5) {
          recentes.add(app_models.LivraisonRecente(
            restaurant: "Commande #${row['id_commande']}", 
            heure: "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}", 
            montant: montant
          ));
        }

        // Semaine et Aujourd'hui (Last 7 days)
        final diffDays = now.difference(dt).inDays;
        if (diffDays <= 7) {
          semaine += montant;
          
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            aujourdhui += montant;
          }

          int dayIndex = dt.weekday - 1; // 0=Lun, 6=Dim
          parJour[dayIndex] += montant;
        }
      }

      return app_models.GainsModel(
        aujourdhui: aujourdhui,
        semaine: semaine,
        parJour: parJour,
        repartitionType: repartitionType,
        livraisonsRecentes: recentes,
        totalLivraisons: totalLivraisons,
        totalDistance: totalDistance,
      );
    } catch (e) {
      debugPrint('Error fetching gains: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
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

      // Fetch recently delivered commands as success notifications
      final cmdRes = await _supabase
          .from('commande')
          .select('id_commande, statut_commande, updated_at, timeline!inner(id_livreur)')
          .eq('statut_commande', 'livree')
          .eq('timeline.id_livreur', idLivreur)
          .order('updated_at', ascending: false)
          .limit(15);
      
      final notifs = (cmdRes as List).map((c) => {
        'titre': 'Livraison réussie 🛵',
        'message': 'Vous avez livré avec succès la commande #${c['id_commande']} ! Excellent travail.',
        'created_at': c['updated_at']
      }).toList();

      return notifs;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> updateLocation(int idCommande, double lat, double lng) async {
    try {
      final pos = {'latitude': lat, 'longitude': lng};
      debugPrint('PUSHING GPS for Commande #$idCommande: $pos');
      
      // We use update first, as the timeline entry should exist since 'acceptation'
      final res = await _supabase.from('timeline').update({
        'position_order': pos
      }).eq('id_commande', idCommande).select();
      
      if (res.isEmpty) {
        debugPrint('WARNING: No timeline row found for #$idCommande. Attempting insert...');
        // If update failed (no row), we might have a sync issue, let's try to find if it's missing
        await _supabase.from('timeline').insert({
          'id_commande': idCommande,
          'position_order': pos,
          'statut_tmlne': 'en_livraison'
        });
      }
    } catch (e) {
      debugPrint('ERROR updating location: $e');
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
