import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../middleware/client_auth_middleware.dart';

import 'client_profile_routes.dart';
import 'client_businesses_routes.dart';
import 'client_orders_routes.dart';
import 'client_notifications_routes.dart';
import 'client_payment_methods_routes.dart';

class ClientMainRoutes {
  Handler get router {
    final router = Router();

    // specific route modules
    router.mount('/profile-address', ClientProfileRoutes().router);
    router.mount('/businesses', ClientBusinessesRoutes().router);
    router.mount('/orders', ClientOrdersRoutes().router);
    router.mount('/notifications', ClientNotificationsRoutes().router);
    router.mount('/payment-methods', ClientPaymentMethodsRoutes().router);

    // Assembly pipeline with client auth middleware
    final pipeline = Pipeline()
        .addMiddleware(clientAuthMiddleware())
        .addHandler(router);

    return pipeline;
  }
}
