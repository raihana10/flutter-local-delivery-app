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
    if (estActif) {
      await mail.sendToUser(
        to: email,
        subject: 'Compte activé — LivrApp',
        html:
            '<p>Bonjour ${nom.isEmpty ? '' : nom},</p>'
            '<p>Votre compte a été <strong>activé</strong>. Vous pouvez vous connecter à l’application.</p>',
      );
    } else {
      await mail.sendToUser(
        to: email,
        subject: 'Compte suspendu — LivrApp',
        html:
            '<p>Bonjour ${nom.isEmpty ? '' : nom},</p>'
            '<p>Votre compte a été <strong>suspendu</strong>. Pour toute question, contactez le support.</p>',
      );
    }
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
    await mail.sendToUser(
      to: email,
      subject: 'Documents approuvés — LivrApp',
      html:
          '<p>Bonjour ${nom.isEmpty ? '' : nom},</p>'
          '<p>Vos documents ont été <strong>validés</strong> et votre compte est désormais actif. '
          'Vous pouvez utiliser l’application.</p>',
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
