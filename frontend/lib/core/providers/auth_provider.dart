import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../data/models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  int? _roleId;
  bool _isLoading = false;
  String? _errorMessage;
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  User? get user => _user;
  int? get roleId => _roleId;
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
        
        // Fetch role-specific ID and est_actif status
        final role = _user!.role.value;
        Map<String, dynamic> userData = _user!.toJson();
        
        if (role == 'livreur') {
          final roleData = await _supabase
              .from('livreur')
              .select()
              .eq('id_user', _user!.id)
              .maybeSingle();
          if (roleData != null) {
            _roleId = roleData['id_livreur'];
            _user = _user!.copyWith(estActif: roleData['est_actif'] == true || roleData['est_actif'] == 1);
          }
        } else if (role == 'business') {
          final roleData = await _supabase
              .from('business')
              .select()
              .eq('id_user', _user!.id)
              .maybeSingle();
          if (roleData != null) {
            _roleId = roleData['id_business'];
            _user = _user!.copyWith(estActif: roleData['est_actif'] == true || roleData['est_actif'] == 1);
          }
        } else if (role == 'client') {
          final roleData = await _supabase
              .from('client')
              .select()
              .eq('id_user', _user!.id)
              .maybeSingle();
          if (roleData != null) {
            _roleId = roleData['id_client'];
          }
        }
        debugPrint("AuthProvider: Logged in as $role with roleId: $_roleId, active: ${_user!.estActif}");
      } else {
        // Fallback if user is in auth but not in public schema yet
        // Attempt to create the user by assuming it's a new Google sign-in redirect.
        final session = _supabase.auth.currentSession;
        if (session != null && session.user.email == email) {
          final nom = session.user.userMetadata?['full_name']?.toString() ??
                      session.user.userMetadata?['name']?.toString() ??
                      email.split('@').first;
          final isNew = await _ensureAppUserFromGoogle(
            email: email,
            nom: nom,
          );
          if (isNew) {
            await _notifyBackendNewRegistration(
              email: email,
              nom: nom,
              role: 'client',
            );
          }
          
          // Re-fetch after creation
          final retryResponse = await _supabase
              .from('app_user')
              .select()
              .eq('email', email)
              .maybeSingle();

          if (retryResponse != null) {
            _user = User.fromJson(retryResponse);
            final roleData = await _supabase.from('client').select().eq('id_user', _user!.id).maybeSingle();
            if (roleData != null) {
              _roleId = roleData['id_client'];
            }
            debugPrint("AuthProvider: Recovered missing user via Google redirect. Logged in as ${_user!.role.value}");
            notifyListeners();
            return;
          }
        }

        debugPrint("AuthProvider: Using fallback user id 0 for $email");
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
      debugPrint("Error fetching user details: \${e}");
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

  Future<bool> updateProfilePicture(dynamic image) async {
    if (_user == null || _user!.role != UserRole.livreur) return false;
    _setLoading(true);
    _clearError();
    try {
      final fileBytes = await (image is String ? File(image).readAsBytes() : (image as dynamic).readAsBytes());
      final String fileName = image is String ? image.split('/').last : (image as dynamic).name; 
      final ext = fileName.split('.').last;
      final path = '${_user!.id}_pdp_${DateTime.now().millisecondsSinceEpoch}.$ext';
      
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
            'date_naissance': request.dateNaissance != null
                ? request.dateNaissance!.toIso8601String().split('T').first
                : null,
            'cni': request.cni,
            'documents_validation': request.documentsValidation,
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
            'pdp': request.profileImageUrl,
            'documents_validation': request.documentsValidation,
            'est_actif': false,
            'is_open': false,
          });
        }

        if (request.latitude != null && request.longitude != null) {
          final adresse = await _supabase.from('adresse').insert({
            'ville': request.ville ?? 'Localisation GPS',
            'latitude': request.latitude,
            'longitude': request.longitude,
          }).select().single();
          await _supabase.from('user_adresse').insert({
            'id_user': userId,
            'id_adresse': adresse['id_adresse'],
            'is_default': true,
          });
        }

        await _notifyBackendNewRegistration(
          email: request.email,
          nom: request.nom,
          role: request.role.value,
        );

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

  Future<void> _notifyBackendNewRegistration({
    required String email,
    required String nom,
    required String role,
  }) async {
    final secret = dotenv.env['NOTIFY_SECRET'];
    if (secret == null || secret.isEmpty) return;
    final base =
        dotenv.env['API_URL'] ?? const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8084');
    try {
      await Dio().post(
        '$base/auth/register-notify',
        data: {'email': email, 'nom': nom, 'role': role},
        options: Options(
          headers: {'X-Notify-Secret': secret, 'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // Ne bloque pas l'inscription si l'API mail est indisponible
    }
  }

  /// Connexion / inscription via Google (compte [UserRole.client] si nouveau).
  ///
  /// - **Web** : utilise le flux OAuth Supabase natif (redirect) → pas besoin de google_sign_in.
  /// - **Android/iOS** : [serverClientId] = ID client OAuth « Web » pour obtenir un `id_token`.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      if (kIsWeb) {
        // ─── Web : OAuth redirect via Supabase ────────────────────────────────
        // signInWithOAuth ouvre la popup/redirect Google et Supabase récupère
        // lui-même le token. L'événement onAuthStateChange(signedIn) gère la suite.
        await _supabase.auth.signInWithOAuth(
          supa.OAuthProvider.google,
          redirectTo: Uri.base.origin, // redirige vers la même origine
        );
        // Sur web, signInWithOAuth déclenche une navigation (redirect).
        // Le retour ici n'arrive que si le provider utilise le mode popup.
        // Dans tous les cas, onAuthStateChange gère _fetchUserDetails.
        return true;
      }

      // ─── Mobile (Android / iOS) ────────────────────────────────────────────
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
      if (webClientId == null || webClientId.isEmpty) {
        _setError(
          'Ajoutez GOOGLE_WEB_CLIENT_ID dans .env (ID client OAuth de type « Application Web » dans Google Cloud Console).',
        );
        return false;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: webClientId,
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        return false;
      }
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _setError(
          'Jeton Google indisponible. Vérifiez GOOGLE_WEB_CLIENT_ID et le SHA-1 Android.',
        );
        return false;
      }
      await _supabase.auth.signInWithIdToken(
        provider: supa.OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      final email = account.email;
      if (email.isEmpty) {
        _setError('Email Google introuvable');
        return false;
      }
      final isNew = await _ensureAppUserFromGoogle(
        email: email,
        nom: account.displayName ?? email.split('@').first,
      );
      if (isNew) {
        await _notifyBackendNewRegistration(
          email: email,
          nom: account.displayName ?? email.split('@').first,
          role: 'client',
        );
      }
      await _fetchUserDetails(email);
      return true;
    } catch (e) {
      _setError('Connexion Google: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Retourne true si un nouvel [app_user] a été créé.
  Future<bool> _ensureAppUserFromGoogle({
    required String email,
    required String nom,
  }) async {
    final existing = await _supabase
        .from('app_user')
        .select('id_user')
        .eq('email', email)
        .maybeSingle();
    if (existing != null) return false;

    final hash = sha256
        .convert(utf8.encode('google:${email}:${Random.secure().nextInt(1 << 30)}'))
        .toString();
    final responseUser = await _supabase.from('app_user').insert({
      'email': email,
      'password': hash,
      'nom': nom,
      'role': 'client',
    }).select().single();
    final userId = responseUser['id_user'] as int;
    await _supabase.from('client').insert({'id_user': userId});
    return true;
  }

  Future<void> logout() async {
    _errorMessage = null;
    await _supabase.auth.signOut();
    _user = null;
    _roleId = null;
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
