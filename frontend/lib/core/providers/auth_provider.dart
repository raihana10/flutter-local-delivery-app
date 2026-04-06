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

  // ✅ Méthode utilitaire pour vérifier le succès quel que soit le type
  bool _isSuccess(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == 'true' || value == '1';
    return false;
  }

  // ✅ Méthode utilitaire pour convertir en int
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> init() async {
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
          .maybeSingle();

      if (response != null) {
        _user = User.fromJson(response);
        
        final role = _user!.role.value;
        
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
      debugPrint("Error fetching user details: ${e.toString()}");
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
      _setError('Erreur lors de la mise à jour: ${e.toString()}');
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

  Future<RegisterResult> register(RegisterRequest request) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      if (request.email.isEmpty || request.password.isEmpty || request.nom.isEmpty) {
        _setError('Tous les champs sont requis');
        return RegisterResult(success: false);
      }

      if (request.password.length < 6) {
        _setError('Le mot de passe doit contenir au moins 6 caractères');
        return RegisterResult(success: false);
      }

      final base = dotenv.env['API_URL'] ?? 'http://localhost:8084';
      
      final response = await Dio().post(
        '$base/auth/register',
        data: {
          'email': request.email,
          'password': request.password,
          'nom': request.nom,
          'num_tl': request.numTl,
          'role': request.role.value,
          'sexe': request.sexe,
          'date_naissance': request.dateNaissance?.toIso8601String(),
          'cni': request.cni,
          'business_type': request.businessType,
          'business_description': request.businessDescription,
          'business_pdp': request.profileImageUrl,
          'documents_validation': request.documentsValidation,
          'latitude': request.latitude,
          'longitude': request.longitude,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && _isSuccess(response.data['success'])) {
        return RegisterResult(
          success: true,
          verificationRequired: _isSuccess(response.data['verification_required']),
          userId: _toInt(response.data['id_user']),
          role: response.data['role'] as String?,
        );
      }
      
      _setError(response.data['error'] ?? 'Erreur d\'inscription');
      return RegisterResult(success: false);
    } catch (e) {
      _setError('Erreur d\'inscription: ${e.toString()}');
      return RegisterResult(success: false);
    } finally {
      _setLoading(false);
    }
  }

  // ✅ MÉTHODE CORRIGÉE - Utilise _isSuccess()
 Future<bool> forgotPassword(String email) async {
  _setLoading(true);
  _clearError();

  try {
    final base = dotenv.env['API_URL'] ?? 'http://localhost:8084';

    final response = await Dio().post(
      '$base/auth/forgot-password',
      data: {'email': email},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.json, // ✅ Force JSON parsing
      ),
    );

    // Safely decode if still a String
    final responseData = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    if (response.statusCode == 200 && _isSuccess(responseData['success'])) {
      return true;
    }

    _setError(responseData['error'] ?? 'Erreur lors de la demande');
    return false;
  } catch (e) {
    _setError('Erreur lors de la demande: ${e.toString()}');
    return false;
  } finally {
    _setLoading(false);
  }
}
  // ✅ MÉTHODE CORRIGÉE - Utilise _isSuccess()
Future<bool> verifyEmail(String email, String code) async {
  _setLoading(true);
  _clearError();

  try {
    final base = dotenv.env['API_URL'] ?? 'http://localhost:8084';

    final response = await Dio().post(
      '$base/auth/verify-email',
      data: {'email': email, 'code': code},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.json, // ✅
      ),
    );

    // ✅ Safe decode if Dio returned a String instead of Map
    final responseData = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    if (response.statusCode == 200 && _isSuccess(responseData['success'])) {
      return true;
    }

    _setError(responseData['error'] ?? 'Erreur de vérification');
    return false;
  } catch (e) {
    _setError('Erreur de vérification: ${e.toString()}');
    return false;
  } finally {
    _setLoading(false);
  }
}
  // ✅ MÉTHODE CORRIGÉE - Utilise _isSuccess()
  Future<bool> resetPassword(String email, String code, String newPassword) async {
  _setLoading(true);
  _clearError();

  try {
    if (newPassword.length < 6) {
      _setError('Le mot de passe doit contenir au moins 6 caractères');
      return false;
    }

    final base = dotenv.env['API_URL'] ?? 'http://localhost:8084';

    final response = await Dio().post(
      '$base/auth/reset-password',
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.json, // ✅
      ),
    );

    // ✅ Safe decode if Dio returned a String instead of Map
    final responseData = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    if (response.statusCode == 200 && _isSuccess(responseData['success'])) {
      return true;
    }

    _setError(responseData['error'] ?? 'Erreur de réinitialisation');
    return false;
  } catch (e) {
    _setError('Erreur de réinitialisation: ${e.toString()}');
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
    final base = dotenv.env['API_URL'] ?? 'http://localhost:8084';
    try {
      await Dio().post(
        '$base/auth/register-notify',
        data: {'email': email, 'nom': nom, 'role': role},
        options: Options(
          headers: {'X-Notify-Secret': secret, 'Content-Type': 'application/json'},
        ),
      );
    } catch (_) {}
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          supa.OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
        return true;
      }

      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim();

      if (webClientId == null || webClientId.isEmpty) {
        _setError('ID client Google Web manquant dans le .env');
        return false;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: (Platform.isIOS || Platform.isMacOS) ? iosClientId : null,
        serverClientId: webClientId,
      );

      final account = await googleSignIn.signIn();
      if (account == null) return false;
      
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _setError('Jeton Google indisponible.');
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