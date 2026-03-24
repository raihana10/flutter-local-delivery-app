import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../supabase/supabase_client.dart';

class ClientBusinessesController {
  
  // Get businesses by type (restaurant, super-marche, pharmacie)
  Future<Response> getBusinessesByType(Request request) async {
    final type = request.url.queryParameters['type'];
    if (type == null || type.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'type parameter is required'}), headers: {'content-type': 'application/json'});
    }

    try {
      final businesses = await SupabaseConfig.client
          .from('business')
          .select('*, app_user(*, user_adresse(*, adresse(*)))')
          .eq('type_business', type)
          .eq('est_actif', true)
          .eq('is_open', true)
          .isFilter('deleted_at', null);

      return Response.ok(jsonEncode({'data': businesses}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  // Get a specific business details
  Future<Response> getBusinessDetails(Request request, String id) async {
    try {
      final business = await SupabaseConfig.client
          .from('business')
          .select('*, app_user(*, user_adresse(*, adresse(*)))')
          .eq('id_business', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (business == null) {
        return Response.notFound(jsonEncode({'error': 'Business not found'}));
      }

      return Response.ok(jsonEncode({'data': business}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  // Get products of a specific business with active promotions
  Future<Response> getBusinessProducts(Request request, String id) async {
    try {
      final products = await SupabaseConfig.client
          .from('produit')
          .select('*, promotion(*)')
          .eq('id_business', id)
          .isFilter('deleted_at', null);

      return Response.ok(jsonEncode({'data': products}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }

  // Get reviews for a specific business
  Future<Response> getBusinessReviews(Request request, String id) async {
    try {
      final reviews = await SupabaseConfig.client
          .from('store_review')
          .select('*, client(*, app_user(*))')
          .eq('id_business', int.tryParse(id) ?? id)
          .isFilter('deleted_at', null);

      print('DEBUG: Found ${reviews.length} reviews for business $id');
      return Response.ok(jsonEncode({'data': reviews}), headers: {'content-type': 'application/json'});
    } catch (e) {
      print('getBusinessReviews Error for $id: $e');
      return Response(500, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
