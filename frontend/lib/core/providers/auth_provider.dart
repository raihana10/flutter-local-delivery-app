import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      final response = await _supabase
          .from('app_user')
          .select()
          .eq('email', email)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response != null) {
        var userData = Map<String, dynamic>.from(response);
        final role = userData['role'] as String?;

        // ✅ Pour livreur et business, lire est_actif depuis la table spécifique
        if (role == 'livreur') {
          final livreurRes = await _supabase
              .from('livreur')
              .select('est_actif')
              .eq('id_user', userData['id_user'])
              .maybeSingle();
          userData['est_actif'] = livreurRes?['est_actif'] ?? false;
        } else if (role == 'business') {
          final businessRes = await _supabase
              .from('business')
              .select('est_actif')
              .eq('id_user', userData['id_user'])
              .maybeSingle();
          userData['est_actif'] = businessRes?['est_actif'] ?? false;
        } else {
          // clients : toujours actifs
          userData['est_actif'] = true;
        }

        _user = User.fromJson(userData);
        print('✅ user fetched: ${_user!.email} role: ${_user!.role.value} actif: ${_user!.estActif}');
      } else {
        print('❌ user not found for email: $email');
        _user = null;
      }
      notifyListeners();
    } catch (e) {
      print('❌ _fetchUserDetails ERROR: $e');
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

  Future<bool> updateProfilePicture(XFile image) async {
    if (_user == null || _user!.role != UserRole.livreur) return false;
    _setLoading(true);
    _clearError();
    try {
      final fileBytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      final path = '\${_user!.id}_pdp_\${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      await _supabase.storage.from('livreur_documents').uploadBinary(
        path, 
        fileBytes, 
        fileOptions: const supa.FileOptions(upsert: true)
      );
      
      await _supabase.from('livreur').update({'pdp': path}).eq('id_user', _user!.id);
      
      await _fetchUserDetails(_user!.email);
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour de la photo: $e');
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

      // Vérifier si email déjà utilisé
      final existing = await _supabase
          .from('app_user')
          .select('id_user')
          .eq('email', request.email)
          .maybeSingle();
      
      if (existing != null) {
        _setError('Cet email est déjà utilisé');
        return false;
      }

      // Hash password SHA256
      final bytes = utf8.encode(request.password);
      final digest = sha256.convert(bytes);
      final hashedPassword = digest.toString();

      // 1. INSERT app_user
      final responseUser = await _supabase.from('app_user').insert({
        'email': request.email,
        'password': hashedPassword,
        'nom': request.nom,
        'num_tl': request.numTl,
        'role': request.role.value,
      }).select().single();

      final int userId = responseUser['id_user'];
      print('USER CREATED id_user: $userId role: ${request.role.value}');

      // Format date
      String? dateNaissanceStr;
      if (request.dateNaissance != null) {
        final d = request.dateNaissance!;
        dateNaissanceStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      // 2. INSERT selon rôle
      if (request.role == UserRole.client) {
        await _supabase.from('client').insert({
          'id_user': userId,
          'sexe': request.sexe,
          'date_naissance': dateNaissanceStr,
        });
        print('CLIENT INSERT SUCCESS');
      } else if (request.role == UserRole.livreur) {
        await _supabase.from('livreur').insert({
          'id_user': userId,
          'sexe': request.sexe,
          'date_naissance': dateNaissanceStr,
          'cni': request.cni,
          'documents_validation': request.documentsValidation,
          'est_actif': false,
        });
        print('LIVREUR INSERT SUCCESS');
      } else if (request.role == UserRole.business) {
        await _supabase.from('business').insert({
          'id_user': userId,
          'type_business': request.businessType,
          'description': request.businessDescription,
          'pdp': request.profileImageUrl,
          'documents_validation': request.documentsValidation,
          'est_actif': false,
          'is_open': false,
        });
        print('BUSINESS INSERT SUCCESS');
      }

      // 3. INSERT adresse
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

      // 4. Charger l'utilisateur
      await _fetchUserDetails(request.email);
      return true;

    } catch (e) {
      print('REGISTER ERROR: $e'); // ← affiche l'erreur exacte
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
