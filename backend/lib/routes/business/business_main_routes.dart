import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'business_stats_routes.dart';
import 'business_profile_routes.dart';
import 'business_notifications_routes.dart';
import 'business_orders_routes.dart';
import 'business_products_routes.dart';

class BusinessMainRoutes {
  Handler get router {
    final router = Router();

    router.mount('/stats', BusinessStatsRoutes().router);
    router.mount('/profile', BusinessProfileRoutes().router);
    router.mount('/notifications', BusinessNotificationsRoutes().router);
    router.mount('/', BusinessProductsRoutes().router);  // ← Produits + Promotions sur /
    router.mount('/', BusinessOrdersRoutes().router);    // ← Commandes aussi sur /

    return router;
  }
}
