import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/stats_controller.dart';

class StatsRoutes {
  Handler get router {
    final router = Router();
    final statsController = StatsController();

    router.get('/revenus', statsController.getRevenus);
    router.get('/livreurs', statsController.getLivreurStats);
    router.get('/businesses', statsController.getBusinessStats);
    router.get('/promotions', statsController.getPromotions);

    return router;
  }
}
