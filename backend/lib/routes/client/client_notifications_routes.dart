import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/client/client_notifications_controller.dart';

class ClientNotificationsRoutes {
  Handler get router {
    final router = Router();
    final controller = ClientNotificationsController();

    router.get('/', controller.getNotifications);
    router.patch('/<id>/read', controller.markAsRead);

    return router;
  }
}
