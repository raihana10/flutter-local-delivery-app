import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/notifications_controller.dart';

class NotificationsRoutes {
  Handler get router {
    final router = Router();
    final notificationsController = NotificationsController();

    router.get('/', notificationsController.getNotifications);
    router.post('/', notificationsController.createNotification);

    return router;
  }
}
