import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Initialize auth state from local storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');
    
    if (token != null && userJson != null) {
      try {
        // In a real app, you'd validate the token with the server
        // For now, we'll just restore the user data
        _user = User.fromJson({
          'id_user': 1,
          'email': 'user@example.com',
          'nom': 'User',
          'role': 'client',
          'est_actif': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock validation - in real app, this would be an API call
      if (email.isEmpty || password.isEmpty) {
        _setError('Email et mot de passe sont requis');
        return false;
      }

      if (email == 'test@test.com' && password == 'password') {
        // Mock successful login
        _user = User(
          id: 1,
          email: email,
          nom: 'Utilisateur Test',
          role: UserRole.client,
          estActif: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', 'mock_token_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString('user_data', _user!.toJson().toString());
        
        notifyListeners();
        return true;
      } else {
        _setError('Email ou mot de passe incorrect');
        return false;
      }
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
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock validation
      if (request.email.isEmpty || request.password.isEmpty || request.nom.isEmpty) {
        _setError('Tous les champs sont requis');
        return false;
      }

      if (request.password.length < 6) {
        _setError('Le mot de passe doit contenir au moins 6 caractères');
        return false;
      }

      // Mock successful registration
      _user = User(
        id: 2,
        email: request.email,
        nom: request.nom,
        role: request.role,
        estActif: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'mock_token_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString('user_data', _user!.toJson().toString());
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur d\'inscription: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _user = null;
    _errorMessage = null;
    
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
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
