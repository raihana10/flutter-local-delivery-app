import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/client/client_payment_methods_controller.dart';

class ClientPaymentMethodsRoutes {
  Handler get router {
    final router = Router();
    final controller = ClientPaymentMethodsController();

    router.get('/', controller.getPaymentMethods);
    router.post('/', controller.addPaymentMethod);
    router.delete('/<id>', controller.deletePaymentMethod);
    router.patch('/<id>/default', controller.setDefaultPaymentMethod);

    return router;
  }
}
