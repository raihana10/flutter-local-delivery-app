import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/client/client_orders_controller.dart';

class ClientOrdersRoutes {
  Handler get router {
    final router = Router();
    final controller = ClientOrdersController();

    router.get('/', controller.getMyOrders);
    router.post('/', controller.createOrder);
    router.get('/<id>/timeline', controller.getOrderTimeline);

    return router;
  }
}
