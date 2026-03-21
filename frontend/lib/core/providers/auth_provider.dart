import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../data/models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> init() async {
    // We are no longer reliably using Supabase Auth session because of confirmation issues.
    // We rely on login() setting the _user variable.
    // For persistence, you'd want to store the user ID in SharedPreferences, but for now we skip session loading.

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final supa.AuthChangeEvent event = data.event;
      final supa.Session? session = data.session;

      if (event == supa.AuthChangeEvent.signedIn && session != null) {
        await _fetchUserDetails(session.user.email!);
      } else if (event == supa.AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserDetails(String email) async {
    try {
      // First try to fetch from the public user table
      final response = await _supabase
          .from('app_user')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        _user = User.fromJson(response);
      } else {
        // Fallback if user is in auth but not in public schema yet
        _user = User(
          id: 0,
          email: email,
          nom: 'Utilisateur',
          role: UserRole.client,
          estActif: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user details: \$e");
    }
  }

  Future<bool> updateUserProfile(
      {required String nom, required String numTl}) async {
    if (_user == null) return false;
    _setLoading(true);
    _clearError();
    try {
      await _supabase.from('app_user').update({
        'nom': nom,
        'num_tl': numTl,
      }).eq('email', _user!.email);

      await _fetchUserDetails(_user!.email);
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      if (email.isEmpty || password.isEmpty) {
        _setError('Email et mot de passe sont requis');
        return false;
      }

      // Check against app_user table directly to bypass Supabase Auth confirmation issues
      final response = await _supabase
          .from('app_user')
          .select()
          .eq('email', email)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) {
        _setError('Identifiants invalides');
        return false;
      }

      // We assume passwords in the DB are hashed with SHA256 as per the register method below
      final bytes = utf8.encode(password);
      final digest = sha256.convert(bytes);
      final hashedPassword = digest.toString();

      if (response['password'] != hashedPassword &&
          response['password'] != password) {
        _setError('Identifiants invalides');
        return false;
      }

      await _fetchUserDetails(email);
      return true;
    } catch (e) {
      _setError('Erreur de connexion: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(RegisterRequest request) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      if (request.email.isEmpty ||
          request.password.isEmpty ||
          request.nom.isEmpty) {
        _setError('Tous les champs sont requis');
        return false;
      }

      if (request.password.length < 6) {
        _setError('Le mot de passe doit contenir au moins 6 caractères');
        return false;
      }

      // 1. Sign up the user in Supabase Auth
      final response = await _supabase.auth.signUp(
        email: request.email,
        password: request.password,
      );

      // 2. Insert into the public custom 'user' table
      if (response.user != null) {
        // Hash the password for the custom `user` table using crypto SHA256
        final bytes = utf8.encode(request.password);
        final digest = sha256.convert(bytes);
        final hashedPassword = digest.toString();

        final userData = {
          'email': request.email,
          'password': hashedPassword,
          'nom': request.nom,
          'num_tl': request.numTl,
          'role': request.role.value,
        };

        final responseUser =
            await _supabase.from('app_user').insert(userData).select().single();
        final int userId = responseUser['id_user'];
        
        // Prepare constraints for Postgres
        String? dateNaissanceStr;
        if (request.dateNaissance != null) {
          dateNaissanceStr = "\${request.dateNaissance!.year}-\${request.dateNaissance!.month.toString().padLeft(2, '0')}-\${request.dateNaissance!.day.toString().padLeft(2, '0')}";
        }

        String? cleanDocsUrl = request.documentsValidation;
        if (cleanDocsUrl != null && cleanDocsUrl.isNotEmpty) {
          cleanDocsUrl = cleanDocsUrl.replaceAll(RegExp(r'https:\/\/[^\/]+\/storage\/v1\/object\/public\/alae\/'), '');
        }

        String? cleanPdpUrl = request.businessPdp;
        if (cleanPdpUrl != null && cleanPdpUrl.isNotEmpty) {
          cleanPdpUrl = cleanPdpUrl.replaceAll(RegExp(r'https:\/\/[^\/]+\/storage\/v1\/object\/public\/alae\/'), '');
        }

        // 3. Insert into the role-specific table based on UserRole
        if (request.role == UserRole.client) {
          await _supabase.from('client').insert({
            'id_user': userId,
            'sexe': request.sexe,
            'date_naissance': dateNaissanceStr,
          });
        } else if (request.role == UserRole.livreur) {
          await _supabase.from('livreur').insert({
            'id_user': userId,
            'sexe': request.sexe,
            'date_naissance': dateNaissanceStr,
            'cni': request.cni,
            'documents_validation': cleanDocsUrl,
            'est_actif': false,
          });
        } else if (request.role == UserRole.business) {
          String bt = 'restaurant';
          if (request.businessType != null) {
            final lowerBt = request.businessType!.toLowerCase();
            if (lowerBt.contains('super')) {
              bt = 'super-marche';
            } else if (lowerBt.contains('pharmacie')) {
              bt = 'pharmacie';
            }
          }
          await _supabase.from('business').insert({
            'id_user': userId,
            'type_business': bt,
            'description': request.businessDescription,
            'documents_validation': cleanDocsUrl,
            'pdp': cleanPdpUrl,
            'est_actif': false,
            'is_open': false,
          });
        }

        // 4. Insert address if geolocation provided
        if (request.latitude != null && request.longitude != null) {
          final adresse = await _supabase.from('adresse').insert({
            'ville': 'Localisation GPS',
            'latitude': request.latitude,
            'longitude': request.longitude,
          }).select().single();

          await _supabase.from('user_adresse').insert({
            'id_user': userId,
            'id_adresse': adresse['id_adresse'],
            'is_default': true,
          });
        }

        // Fetch details synchronously before returning true so the UI has the role
        await _fetchUserDetails(request.email);
        return true;
      }
      return false;
    } on supa.AuthException catch (e) {
      _setError('Erreur d\'inscription: ${e.message}');
      return false;
    } catch (e) {
      _setError('Erreur d\'inscription: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    await _supabase.auth.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
}
