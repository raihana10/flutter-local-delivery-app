import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../supabase/supabase_client.dart';
import '../services/email_service.dart';

class UsersController {
  Future<void> _sendAccountStatusEmail({
    required String idUser,
    required bool estActif,
  }) async {
    final u = await SupabaseConfig.client
        .from('app_user')
        .select('email, nom')
        .eq('id_user', idUser)
        .maybeSingle();
    if (u == null) return;
    final email = u['email'] as String?;
    final nom = u['nom'] as String? ?? '';
    if (email == null || email.isEmpty) return;
    final mail = EmailService.fromEnv();
    final status = estActif ? 'activé' : 'suspendu';
    final message = estActif
        ? 'Votre compte a été activé. Vous pouvez maintenant vous connecter et utiliser toutes les fonctionnalités de l\'application.'
        : 'Votre compte a été suspendu. Pour toute question ou pour contester cette décision, veuillez contacter notre support.';

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
      <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 600;">Local Delivery</h1>
      <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">Mise à jour de votre compte</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 30px;">
      <h2 style="color: #1f2937; margin: 0 0 20px; font-size: 20px; font-weight: 600;">
        Bonjour ${nom.isEmpty ? 'Utilisateur' : nom},
      </h2>

      <div style="background-color: ${estActif ? '#ecfdf5' : '#fef2f2'}; border: 1px solid ${estActif ? '#d1fae5' : '#fecaca'}; border-radius: 8px; padding: 20px; margin: 20px 0;">
        <div style="display: flex; align-items: center;">
          <div style="width: 20px; height: 20px; border-radius: 50%; background-color: ${estActif ? '#10b981' : '#ef4444'}; margin-right: 12px; flex-shrink: 0;"></div>
          <div>
            <p style="margin: 0; font-size: 16px; font-weight: 600; color: ${estActif ? '#065f46' : '#991b1b'};">
              Compte ${status}
            </p>
          </div>
        </div>
      </div>

      <p style="color: #4b5563; line-height: 1.6; margin: 20px 0; font-size: 16px;">
        $message
      </p>

      ${estActif ? '''
      <div style="text-align: center; margin: 30px 0;">
        <a href="#" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: 600; display: inline-block;">
          Se connecter maintenant
        </a>
      </div>
      ''' : ''}

      <div style="border-top: 1px solid #e5e7eb; padding-top: 20px; margin-top: 30px;">
        <p style="color: #6b7280; font-size: 14px; margin: 0;">
          Si vous avez des questions, n'hésitez pas à nous contacter à l'adresse
          <a href="mailto:support@localdelivery.com" style="color: #667eea; text-decoration: none;">support@localdelivery.com</a>
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
      subject: 'Compte $status — Local Delivery',
      html: html,
    );
  }

  Future<void> _sendDocumentsValidatedEmail(String idUser) async {
    final u = await SupabaseConfig.client
        .from('app_user')
        .select('email, nom')
        .eq('id_user', idUser)
        .maybeSingle();
    if (u == null) return;
    final email = u['email'] as String?;
    final nom = u['nom'] as String? ?? '';
    if (email == null || email.isEmpty) return;
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
    <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 40px 30px; text-align: center;">
      <div style="width: 60px; height: 60px; background-color: #ffffff; border-radius: 12px; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center;">
        <span style="font-size: 24px; font-weight: bold; color: #10b981;">✓</span>
      </div>
      <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 600;">Documents Approuvés</h1>
      <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">Local Delivery</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 30px;">
      <h2 style="color: #1f2937; margin: 0 0 20px; font-size: 20px; font-weight: 600;">
        Félicitations ${nom.isEmpty ? 'Utilisateur' : nom} !
      </h2>

      <div style="background-color: #ecfdf5; border: 1px solid #d1fae5; border-radius: 8px; padding: 20px; margin: 20px 0;">
        <div style="display: flex; align-items: center;">
          <div style="width: 20px; height: 20px; border-radius: 50%; background-color: #10b981; margin-right: 12px; flex-shrink: 0;"></div>
          <div>
            <p style="margin: 0; font-size: 16px; font-weight: 600; color: #065f46;">
              Documents validés avec succès
            </p>
          </div>
        </div>
      </div>

      <p style="color: #4b5563; line-height: 1.6; margin: 20px 0; font-size: 16px;">
        Vos documents ont été examinés et approuvés par notre équipe. Votre compte est désormais actif et vous pouvez utiliser toutes les fonctionnalités de l'application Local Delivery.
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <a href="#" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: 600; display: inline-block;">
          Commencer maintenant
        </a>
      </div>

      <div style="border-top: 1px solid #e5e7eb; padding-top: 20px; margin-top: 30px;">
        <p style="color: #6b7280; font-size: 14px; margin: 0;">
          Bienvenue dans la communauté Local Delivery ! Si vous avez des questions, contactez-nous à
          <a href="mailto:support@localdelivery.com" style="color: #10b981; text-decoration: none;">support@localdelivery.com</a>
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
      subject: 'Documents approuvés — Local Delivery',
      html: html,
    );
  }

  // NOTE: PostgREST JOINs work if foreign keys are properly set up (e.g. user(client(...))).
  // Without exact schema FK knowledge, we assume standard one-to-one joining structures.
  // The generic fallback is querying 'user' and joining the specific role table.

  Future<Response> getClients(Request request) async {
    try {
      final clients = await SupabaseConfig.client
          .from('app_user')
          .select('*, client(*)')
          .eq('role', 'client')
          .isFilter('deleted_at', null);

      final formatted = clients.map((item) {
        final user = item['app_user'] ?? item;
        return {
          ...Map<String, dynamic>.from(item),
          'nom': user['nom'] ?? '',
          'email': user['email'] ?? '',
          'role': user['role'] ?? 'client',
          'created_at': user['created_at'] ?? item['created_at'],
          'id_user': user['id_user'] ?? item['id_user'],
        };
      }).toList();

      return Response.ok(
        jsonEncode({'data': formatted}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getLivreurs(Request request) async {
    try {
      final livreurs = await SupabaseConfig.client
          .from('app_user')
          .select('*, livreur(*)')
          .eq('role', 'livreur')
          .isFilter('deleted_at', null);

      final formatted = livreurs.map((item) {
        final user = item['app_user'] ?? item;
        final livreurInfo = (item['livreur'] is List && (item['livreur'] as List).isNotEmpty)
            ? item['livreur'][0]
            : (item['livreur'] is Map ? item['livreur'] : {});
            
        return {
          ...Map<String, dynamic>.from(item),
          'nom': user['nom'] ?? '',
          'email': user['email'] ?? '',
          'role': user['role'] ?? 'livreur',
          'created_at': user['created_at'] ?? item['created_at'],
          'id_user': user['id_user'] ?? item['id_user'],
          'est_actif': livreurInfo['est_actif'] ?? true,
          'documents_validation': livreurInfo['documents_validation'],
        };
      }).toList();

      return Response.ok(
        jsonEncode({'data': formatted}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getBusinesses(Request request) async {
    try {
      final businesses = await SupabaseConfig.client
          .from('app_user')
          .select('*, business(*)')
          .eq('role', 'business')
          .isFilter('deleted_at', null);

      final formatted = businesses.map((item) {
        final user = item['app_user'] ?? item;
        final businessInfo = (item['business'] is List && (item['business'] as List).isNotEmpty)
            ? item['business'][0]
            : (item['business'] is Map ? item['business'] : {});

        return {
          ...Map<String, dynamic>.from(item),
          'nom': user['nom'] ?? '',
          'email': user['email'] ?? '',
          'role': user['role'] ?? 'business',
          'created_at': user['created_at'] ?? item['created_at'],
          'id_user': user['id_user'] ?? item['id_user'],
          'type_business': businessInfo['type_business'] ?? 'N/A',
          'est_actif': businessInfo['est_actif'] ?? true,
          'documents_validation': businessInfo['documents_validation'],
        };
      }).toList();

      return Response.ok(
        jsonEncode({'data': formatted}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getUserDetail(Request request, String id) async {
    try {
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('*, client(*), livreur(*), business(*)')
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (user == null) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      return Response.ok(
        jsonEncode({'data': user}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> toggleUserStatus(Request request, String id) async {
    try {
      final userRes = await SupabaseConfig.client
          .from('app_user')
          .select('role')
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (userRes == null) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      final role = userRes['role'] as String;

      if (role == 'client') {
        // Pour les clients : toggle un champ est_actif dans app_user (ou ajouter si absent)
        // On utilise un champ custom dans app_user — est_actif bool
        final clientRes = await SupabaseConfig.client
            .from('app_user')
            .select('est_actif')
            .eq('id_user', id)
            .maybeSingle();

        final currentStatus = clientRes?['est_actif'] as bool? ?? true;
        final newStatus = !currentStatus;

        final updated = await SupabaseConfig.client
            .from('app_user')
            .update({'est_actif': newStatus})
            .eq('id_user', id)
            .select();

        await _sendAccountStatusEmail(idUser: id, estActif: newStatus);

        return Response.ok(
          jsonEncode({'success': true, 'data': updated}),
          headers: {'content-type': 'application/json'},
        );
      }

      final table = role == 'livreur' ? 'livreur' : 'business';

      final roleRecord = await SupabaseConfig.client
          .from(table)
          .select('est_actif')
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (roleRecord == null) {
        return Response.notFound(
          jsonEncode({'error': '$table record not found'}),
        );
      }

      final newStatus = !(roleRecord['est_actif'] as bool);

      final updatedUser = await SupabaseConfig.client
          .from(table)
          .update({'est_actif': newStatus})
          .eq('id_user', id)
          .select();

      await _sendAccountStatusEmail(idUser: id, estActif: newStatus);

      return Response.ok(
        jsonEncode({'success': true, 'data': updatedUser}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> validateUser(Request request, String id) async {
    try {
      final user = await SupabaseConfig.client
          .from('app_user')
          .select('role')
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (user == null) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      final role = user['role'] as String;
      if (role == 'client') {
        return Response(
          400,
          body: jsonEncode({'error': 'Clients do not need validation'}),
        );
      }

      final table = role == 'livreur' ? 'livreur' : 'business';
      final Map<String, dynamic> updateData = {'est_actif': true};

      final updatedUser = await SupabaseConfig.client
          .from(table)
          .update(updateData)
          .eq('id_user', id)
          .isFilter('deleted_at', null)
          .select();

      await _sendDocumentsValidatedEmail(id);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'User validated',
          'data': updatedUser,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> deleteUser(Request request, String id) async {
    try {
      await SupabaseConfig.client
          .from('app_user')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id_user', id);

      return Response.ok(
        jsonEncode({'success': true, 'message': 'User deleted successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
