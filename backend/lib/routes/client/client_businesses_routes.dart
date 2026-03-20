import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/client/client_businesses_controller.dart';

class ClientBusinessesRoutes {
  Handler get router {
    final router = Router();
    final controller = ClientBusinessesController();

    // Query param: ?type=restaurant or type=pharmacie or type=super-marche
    router.get('/', controller.getBusinessesByType);

    // Specific business details
    router.get('/<id>', controller.getBusinessDetails);

    // Products of a business
    router.get('/<id>/products', controller.getBusinessProducts);

    // Reviews
    router.get('/<id>/reviews', controller.getBusinessReviews);

    return router;
  }
}
