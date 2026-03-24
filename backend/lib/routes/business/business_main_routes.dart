import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'business_stats_routes.dart';
import 'business_profile_routes.dart';
import 'business_notifications_routes.dart';

class BusinessMainRoutes {
  Handler get router {
    final router = Router();

    router.mount('/stats', BusinessStatsRoutes().router);
    router.mount('/profile', BusinessProfileRoutes().router);
    router.mount('/notifications', BusinessNotificationsRoutes().router);

    return router;
  }
}
