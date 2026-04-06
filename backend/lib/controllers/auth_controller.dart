import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import '../supabase/supabase_client.dart';
import '../services/email_service.dart';

class AuthController {
  // Rate limiting storage (in production, use Redis or similar)
  final Map<String, List<DateTime>> _rateLimitStore = {};

  // Clean up old entries periodically
  void _cleanupRateLimit() {
    final now = DateTime.now();
    _rateLimitStore.removeWhere((key, timestamps) {
      timestamps.removeWhere((timestamp) => now.difference(timestamp).inMinutes > 15);
      return timestamps.isEmpty;
    });
  }

  bool _checkRateLimit(String key, int maxRequests, Duration window) {
    _cleanupRateLimit();
    final now = DateTime.now();
    final timestamps = _rateLimitStore[key] ?? [];
    
    // Remove old timestamps outside the window
    timestamps.removeWhere((timestamp) => now.difference(timestamp) > window);
    
    if (timestamps.length >= maxRequests) {
      return false; // Rate limit exceeded
    }
    
    timestamps.add(now);
    _rateLimitStore[key] = timestamps;
    return true;
  }
  Future<Response> login(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      final email = body['email'];
      final password = body['password'];

      if (email == null || password == null) {
        return Response(
          400,
          body: jsonEncode({
            'success': false,
            'error': 'Email and password are required',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Query Supabase admin table
      final response = await SupabaseConfig.client
          .from('admin')
          .select()
          .eq('email', email)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) {
        return Response(
          403,
          body: jsonEncode({'success': false, 'error': 'Invalid credentials'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Verify password
      final hash = response['password'];
      final isMatch = BCrypt.checkpw(password, hash);

      if (!isMatch) {
        return Response(
          403,
          body: jsonEncode({'success': false, 'error': 'Invalid credentials'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'id_admin': response['id_admin'],
          'email': response['email'],
          // For simple memory flag simulation without JWT, we return the admin ID to be used as x-admin-id header by the client
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('LOGIN ERROR: $e');
      return Response(
        500,
        body: jsonEncode({'success': false, 'error': 'Internal server error'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> register(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      final email = body['email'];
      final password = body['password'];
      final nom = body['nom'];
      final numTl = body['num_tl'];
      final role = body['role'];
      
      final sexe = body['sexe'];
      final dateNaissance = body['date_naissance'];
      final cni = body['cni'];
      final businessType = body['business_type'];
      final businessDescription = body['business_description'];
      final businessPdp = body['business_pdp'];
      final documentsValidation = body['documents_validation'];
      final latitude = body['latitude'];
      final longitude = body['longitude'];

      if (email == null || password == null || nom == null || role == null) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Missing required fields'}));
      }

      // Rate limiting for registration
      if (!_checkRateLimit('register_$email', 3, Duration(minutes: 15))) {
        return Response(429, body: jsonEncode({'success': false, 'error': 'Trop de tentatives. Réessayez plus tard.'}));
      }

      // 1. Hash du password
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      // 2. Générer code de vérification pour les clients
      String? verificationCode;
      DateTime? verificationCodeExpiresAt;
      bool emailVerified = true; // Par défaut vérifié pour non-clients

      if (role == 'client') {
        // Générer un code de 6 chiffres
        final random = Random();
        verificationCode = (100000 + random.nextInt(900000)).toString();
        verificationCodeExpiresAt = DateTime.now().add(Duration(minutes: 15));
        emailVerified = false;

        // Envoyer l'email de vérification AVANT de hacher
        await _sendVerificationEmail(email, nom, verificationCode);

        // Hacher le code après envoi
        verificationCode = BCrypt.hashpw(verificationCode, BCrypt.gensalt());
      }

      // 3. INSERT app_user
      final user = await SupabaseConfig.client.from('app_user').insert({
        'email': email,
        'password': hashedPassword,
        'nom': nom,
        'num_tl': numTl,
        'role': role,
        'verification_code': verificationCode,
        'verification_code_expires_at': verificationCodeExpiresAt?.toIso8601String(),
        'email_verified': emailVerified,
      }).select().single();

      final idUser = user['id_user'];

      // 4. INSERT selon le rôle
      if (role == 'client') {
        await SupabaseConfig.client.from('client').insert({
          'id_user': idUser,
          'sexe': sexe,
          'date_naissance': dateNaissance,
        });
      } else if (role == 'livreur') {
        await SupabaseConfig.client.from('livreur').insert({
          'id_user': idUser,
          'sexe': sexe,
          'date_naissance': dateNaissance,
          'cni': cni,
          'documents_validation': documentsValidation,
          'est_actif': false, // en attente validation admin
        });
      } else if (role == 'business') {
        await SupabaseConfig.client.from('business').insert({
          'id_user': idUser,
          'type_business': businessType,
          'description': businessDescription,
          'pdp': businessPdp,
          'documents_validation': documentsValidation,
          'est_actif': false, // en attente validation admin
          'is_open': false,
        });
      }

      // 4. INSERT adresse si latitude/longitude fournies
      if (latitude != null && longitude != null) {
        final adresse = await SupabaseConfig.client.from('adresse').insert({
          'ville': 'Localisation GPS',
          'latitude': latitude,
          'longitude': longitude,
        }).select().single();

        await SupabaseConfig.client.from('user_adresse').insert({
          'id_user': idUser,
          'id_adresse': adresse['id_adresse'],
          'is_default': true,
        });
      }

      // 5. Retourner l'utilisateur créé
      return Response.ok(jsonEncode({
        'success': true,
        'id_user': idUser,
        'role': role,
        'verification_required': role == 'client' && !emailVerified,
      }), headers: {'content-type': 'application/json'});
    } catch (e) {
      print('REGISTER ERROR: $e');
      return Response(
        500,
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
 Future<void> _sendVerificationEmail(String email, String nom, String plainCode) async {
    // Supprimez cette ligne qui redéclare la variable :
    // final plainCode = '123456'; // ← À SUPPRIMER
    
    final mail = EmailService.fromEnv();
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center;">
      <div style="width: 60px; height: 60px; background-color: #ffffff; border-radius: 12px; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center;">
        <span style="font-size: 24px; font-weight: bold; color: #667eea;">LD</span>
      </div>
      <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 600;">Vérification Email</h1>
      <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">Local Delivery</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 30px;">
      <h2 style="color: #1f2937; margin: 0 0 20px; font-size: 20px; font-weight: 600;">
        Bonjour ${nom.isEmpty ? 'Utilisateur' : nom},
      </h2>

      <p style="color: #4b5563; line-height: 1.6; margin: 20px 0; font-size: 16px;">
        Merci de vous être inscrit sur Local Delivery ! Pour finaliser votre inscription, veuillez vérifier votre adresse email en saisissant le code ci-dessous :
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <div style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; padding: 20px; border-radius: 12px; font-size: 32px; font-weight: bold; letter-spacing: 8px; font-family: 'Courier New', monospace;">
          $plainCode
        </div>
      </div>

      <p style="color: #6b7280; font-size: 14px; margin: 20px 0; text-align: center;">
        Ce code expire dans 15 minutes.
      </p>

      <div style="border-top: 1px solid #e5e7eb; padding-top: 20px; margin-top: 30px;">
        <p style="color: #6b7280; font-size: 14px; margin: 0;">
          Si vous n'avez pas demandé cette vérification, ignorez cet email.
        </p>
      </div>
    </div>

    <!-- Footer -->
    <div style="background-color: #f9fafb; padding: 20px 30px; text-align: center; border-top: 1px solid #e5e7eb;">
      <p style="color: #6b7280; font-size: 12px; margin: 0;">
        © 2024 Local Delivery. Tous droits réservés.
      </p>
    </div>
  </div>
</body>
</html>
''';

    await mail.sendToUser(
      to: email,
      subject: 'Vérifiez votre email — Local Delivery',
      html: html,
    );
}
  Future<Response> verifyEmail(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      final email = body['email'];
      final code = body['code'];

      if (email == null || code == null) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Email et code requis'}));
      }

      // Rate limiting
      if (!_checkRateLimit('verify_$email', 5, Duration(minutes: 15))) {
        return Response(429, body: jsonEncode({'success': false, 'error': 'Trop de tentatives. Réessayez plus tard.'}));
      }

      // Récupérer l'utilisateur
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('verification_code, verification_code_expires_at, email_verified')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        return Response(404, body: jsonEncode({'success': false, 'error': 'Utilisateur non trouvé'}));
      }

      if (user['email_verified'] == true) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Email déjà vérifié'}));
      }

      final hashedCode = user['verification_code'];
      final expiresAt = user['verification_code_expires_at'];

      if (hashedCode == null || expiresAt == null) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Code de vérification manquant'}));
      }

      // Vérifier expiration
      final expiryDate = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiryDate)) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Code expiré'}));
      }

      // Vérifier le code
      if (!BCrypt.checkpw(code, hashedCode)) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Code invalide'}));
      }

      // Marquer comme vérifié
      await SupabaseConfig.client
          .from('app_user')
          .update({
            'email_verified': true,
            'verification_code': null,
            'verification_code_expires_at': null,
          })
          .eq('email', email);

      return Response.ok(jsonEncode({'success': true, 'message': 'Email vérifié avec succès'}));
    } catch (e) {
      print('VERIFY EMAIL ERROR: $e');
      return Response(500, body: jsonEncode({'success': false, 'error': 'Erreur interne'}));
    }
  }

  Future<Response> forgotPassword(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      final email = body['email'];

      if (email == null) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Email requis'}));
      }

      // Rate limiting
      if (!_checkRateLimit('forgot_$email', 3, Duration(hours: 1))) {
        return Response(429, body: jsonEncode({'success': false, 'error': 'Trop de demandes. Réessayez plus tard.'}));
      }

      // Vérifier si l'utilisateur existe
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('nom')
          .eq('email', email)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (user == null) {
        // Ne pas révéler si l'email existe ou non pour sécurité
        return Response.ok(jsonEncode({'success': true, 'message': 'Si cet email existe, un code a été envoyé'}));
      }

      final nom = user['nom'] ?? '';

      // Générer code de reset
      final random = Random();
      final resetCode = (100000 + random.nextInt(900000)).toString();
      final hashedResetCode = BCrypt.hashpw(resetCode, BCrypt.gensalt());
      final expiresAt = DateTime.now().add(Duration(minutes: 15));

      // Envoyer l'email AVANT de stocker le hash
      await _sendResetPasswordEmail(email, nom, resetCode);

      // Stocker le code hashé
      await SupabaseConfig.client
          .from('app_user')
          .update({
            'reset_code': hashedResetCode,
            'reset_code_expires_at': expiresAt.toIso8601String(),
          })
          .eq('email', email);

      return Response.ok(jsonEncode({'success': true, 'message': 'Code envoyé par email'}));
    } catch (e) {
      print('FORGOT PASSWORD ERROR: $e');
      return Response(500, body: jsonEncode({'success': false, 'error': 'Erreur interne'}));
    }
  }

  Future<Response> resetPassword(Request request) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload);

      final email = body['email'];
      final code = body['code'];
      final newPassword = body['new_password'];

      if (email == null || code == null || newPassword == null) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Tous les champs requis'}));
      }

      if (newPassword.length < 6) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Mot de passe trop court'}));
      }

      // Rate limiting
      if (!_checkRateLimit('reset_$email', 5, Duration(minutes: 15))) {
        return Response(429, body: jsonEncode({'success': false, 'error': 'Trop de tentatives. Réessayez plus tard.'}));
      }

      // Récupérer l'utilisateur
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('reset_code, reset_code_expires_at')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        return Response(404, body: jsonEncode({'success': false, 'error': 'Utilisateur non trouvé'}));
      }

      final hashedCode = user['reset_code'];
      final expiresAt = user['reset_code_expires_at'];

      if (hashedCode == null || expiresAt == null) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Aucune demande de reset trouvée'}));
      }

      // Vérifier expiration
      final expiryDate = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiryDate)) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Code expiré'}));
      }

      // Vérifier le code
      if (!BCrypt.checkpw(code, hashedCode)) {
        return Response(400, body: jsonEncode({'success': false, 'error': 'Code invalide'}));
      }

      // Mettre à jour le mot de passe
      final bytes = utf8.encode(newPassword); // ✅ 'newPassword'
      final hashedPassword = sha256.convert(bytes).toString();
      await SupabaseConfig.client
          .from('app_user')
          .update({
            'password': hashedPassword,
            'reset_code': null,
            'reset_code_expires_at': null,
          })
          .eq('email', email);

      return Response.ok(jsonEncode({'success': true, 'message': 'Mot de passe mis à jour'}));
    } catch (e) {
      print('RESET PASSWORD ERROR: $e');
      return Response(500, body: jsonEncode({'success': false, 'error': 'Erreur interne'}));
    }
  }

  Future<void> _sendResetPasswordEmail(String email, String nom, String plainCode) async {
    final mail = EmailService.fromEnv();
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); padding: 40px 30px; text-align: center;">
      <div style="width: 60px; height: 60px; background-color: #ffffff; border-radius: 12px; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center;">
        <span style="font-size: 24px; font-weight: bold; color: #f59e0b;">🔑</span>
      </div>
      <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 600;">Réinitialisation</h1>
      <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">Local Delivery</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 30px;">
      <h2 style="color: #1f2937; margin: 0 0 20px; font-size: 20px; font-weight: 600;">
        Bonjour ${nom.isEmpty ? 'Utilisateur' : nom},
      </h2>

      <p style="color: #4b5563; line-height: 1.6; margin: 20px 0; font-size: 16px;">
        Vous avez demandé la réinitialisation de votre mot de passe. Utilisez le code ci-dessous pour créer un nouveau mot de passe :
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <div style="display: inline-block; background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: #ffffff; padding: 20px; border-radius: 12px; font-size: 32px; font-weight: bold; letter-spacing: 8px; font-family: 'Courier New', monospace;">
          $plainCode
        </div>
      </div>

      <p style="color: #6b7280; font-size: 14px; margin: 20px 0; text-align: center;">
        Ce code expire dans 15 minutes.
      </p>

      <div style="border-top: 1px solid #e5e7eb; padding-top: 20px; margin-top: 30px;">
        <p style="color: #6b7280; font-size: 14px; margin: 0;">
          Si vous n'avez pas demandé cette réinitialisation, ignorez cet email. Votre mot de passe reste inchangé.
        </p>
      </div>
    </div>

    <!-- Footer -->
    <div style="background-color: #f9fafb; padding: 20px 30px; text-align: center; border-top: 1px solid #e5e7eb;">
      <p style="color: #6b7280; font-size: 12px; margin: 0;">
        © 2024 Local Delivery. Tous droits réservés.
      </p>
    </div>
  </div>
</body>
</html>
''';

    await mail.sendToUser(
      to: email,
      subject: 'Réinitialisation de mot de passe — Local Delivery',
      html: html,
    );
  }
  /// Appelé par l’app Flutter après inscription (secret [NOTIFY_SECRET]).
  Future<Response> registerNotify(Request request) async {
    try {
      final env = DotEnv(includePlatformEnvironment: true)..load();
      final expected = env['NOTIFY_SECRET'];
      final secret = request.headers['x-notify-secret'];
      if (expected == null ||
          expected.isEmpty ||
          secret == null ||
          secret != expected) {
        return Response(
          403,
          body: jsonEncode({'success': false, 'error': 'Forbidden'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final payload = jsonDecode(await request.readAsString());
      final email = payload['email']?.toString() ?? '';
      final nom = payload['nom']?.toString() ?? '';
      final role = payload['role']?.toString() ?? '';

      final mail = EmailService.fromEnv();
      await mail.notifyAdmins(
        subject: 'Nouvelle inscription à traiter — LivrApp',
        html:
            '<p>Un nouvel utilisateur s’est inscrit.</p>'
            '<ul>'
            '<li><strong>Nom :</strong> ${nom.isEmpty ? '—' : nom}</li>'
            '<li><strong>Email :</strong> $email</li>'
            '<li><strong>Rôle :</strong> $role</li>'
            '</ul>'
            '<p>Connectez-vous à l’administration pour valider les documents si nécessaire.</p>',
      );

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
