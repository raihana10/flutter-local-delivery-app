import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/business/business_stats_controller.dart';

class BusinessStatsRoutes {
  Handler get router {
    final router = Router();
    final controller = BusinessStatsController();

    router.get('/dashboard', controller.getDashboardStats);

    return router;
  }
}
