import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/business_controller.dart';

class BusinessOrdersRoutes {
  Handler get router {
    final router = Router();
    final controller = BusinessController();

    // GET /business/<id>/commandes
    router.get('/<id>/commandes', controller.getBusinessCommandes);

    // PATCH /business/<id>/commandes/<cid>/statut
    router.patch('/<id>/commandes/<cid>/statut', controller.updateCommandeStatut);

    return router;
  }
}
