import 'package:shelf/shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/client/client_businesses_controller.dart';
import '../../controllers/client/client_payment_methods_controller.dart';
import '../../controllers/client/client_reviews_controller.dart';

class ClientBusinessesRoutes {
  Handler get router {
    final router = Router();
    final controller = ClientBusinessesController();

    // List businesses by type
    router.get('/', controller.getBusinessesByType);
    
    // Detailed business view
    router.get('/<id>', controller.getBusinessDetails);
    
    // Products of a business
    router.get('/<id>/products', controller.getBusinessProducts);
    
    // Reviews
    final reviewsController = ClientReviewsController();
    router.get('/<id>/reviews', controller.getBusinessReviews);
    router.post('/<id>/reviews', reviewsController.addReview);

    return router;
  }
}
