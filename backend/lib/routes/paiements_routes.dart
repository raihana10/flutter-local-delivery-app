import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/paiements_controller.dart';

class PaiementsRoutes {
  Handler get router {
    final router = Router();
    final paiementsController = PaiementsController();

    router.get('/', paiementsController.getPaiements);
    router.get('/commissions', paiementsController.getCommissions);
    router.get('/livreurs/<id>', paiementsController.getLivreurEarnings);

    return router;
  }
}
