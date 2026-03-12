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

  // Initialize auth state from local storage or Supabase session
  Future<void> init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchUserDetails(session.user.email!);
    }
    
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

  Future<bool> updateUserProfile({required String nom, required String numTl}) async {
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

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch details synchronously before returning true so the UI has the role
        await _fetchUserDetails(email);
        return true; 
      }
      return false;
    } on supa.AuthException catch (e) {
      _setError('Erreur de connexion: ${e.message}');
      return false;
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
      if (request.email.isEmpty || request.password.isEmpty || request.nom.isEmpty) {
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
         
         final responseUser = await _supabase.from('app_user').insert(userData).select().single();
         final int userId = responseUser['id_user'];
         
         // 3. Insert into the role-specific table based on UserRole
         if (request.role == UserRole.client) {
            await _supabase.from('client').insert({
              'id_user': userId,
              'sexe': request.sexe,
            });
         } else if (request.role == UserRole.livreur) {
            await _supabase.from('livreur').insert({
              'id_user': userId,
              'sexe': request.sexe,
              'cni': request.cni,
            });
         } else if (request.role == UserRole.business) {
            String bt = 'restaurant';
            if (request.businessType != null) {
               final lowerBt = request.businessType!.toLowerCase();
               if (lowerBt.contains('super')) bt = 'super-marche';
               else if (lowerBt.contains('pharmacie')) bt = 'pharmacie';
            }
            await _supabase.from('business').insert({
              'id_user': userId,
              'type_business': bt,
              'description': request.businessDescription,
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
