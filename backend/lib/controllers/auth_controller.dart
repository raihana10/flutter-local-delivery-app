import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import '../supabase/supabase_client.dart';

class AuthController {
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

      // 1. Hash du password
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // 2. INSERT app_user
      final user = await SupabaseConfig.client.from('app_user').insert({
        'email': email,
        'password': hashedPassword,
        'nom': nom,
        'num_tl': numTl,
        'role': role,
      }).select().single();

      final idUser = user['id_user'];

      // 3. INSERT selon le rôle
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
}
