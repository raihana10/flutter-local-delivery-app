import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/commandes_controller.dart';

class CommandesRoutes {
  Handler get router {
    final router = Router();
    final commandesController = CommandesController();

    router.get('/', commandesController.getCommandes);
    router.get('/<id>', commandesController.getCommandeDetail);
    router.patch('/<id>/rembourse', commandesController.rembourseCommande);

    return router;
  }
}
