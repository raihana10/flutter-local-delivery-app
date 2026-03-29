import 'package:shelf_router/shelf_router.dart';
import '../controllers/admin_config_controller.dart';

class AdminConfigRoutes {
  Router get router {
    final router = Router();
    final controller = AdminConfigController();

    router.get('/', controller.getConfigs);
    router.post('/', controller.updateConfig);

    return router;
  }
}
