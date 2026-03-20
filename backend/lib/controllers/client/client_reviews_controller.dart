import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class ClientReviewsController {
  Future<Response> addReview(Request request, String idBusiness) async {
    final userId = request.headers['x-client-id'];
    if (userId == null) {
      return Response.forbidden(jsonEncode({'error': 'Unauthorized'}));
    }

    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final rating = data['rating'];
      final comment = data['comment'];

      if (rating == null) {
        return Response(400, body: jsonEncode({'error': 'rating is required'}), headers: {'content-type': 'application/json'});
      }

      // Get id_client
      final clientRecord = await SupabaseConfig.client
          .from('client')
          .select('id_client')
          .eq('id_user', userId)
          .maybeSingle();
      
      if (clientRecord == null) {
        return Response.forbidden(jsonEncode({'error': 'Client profile not found.'}));
      }

      final newReview = await SupabaseConfig.client.from('store_review').insert({
        'id_client': clientRecord['id_client'],
        'id_business': int.parse(idBusiness),
        'evaluation': rating is num ? rating : int.tryParse(rating.toString()) ?? 0,
        'commentaire': comment?.toString(),
      }).select().single();

      return Response.ok(jsonEncode({'success': true, 'data': newReview}), headers: {'content-type': 'application/json'});
    } catch (e) {
      print('addReview Error for business $idBusiness: $e');
      if (e.toString().contains('23505') || e.toString().contains('unique constraint')) {
        return Response(409, body: jsonEncode({'error': 'ERREUR : La base de données bloque les avis multiples. LANCEZ LE SQL proposé pour supprimer la contrainte UNIQUE.'}), headers: {'content-type': 'application/json'});
      }
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
