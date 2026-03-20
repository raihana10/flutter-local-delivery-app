import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/business/business_notifications_controller.dart';

class BusinessNotificationsRoutes {
  Handler get router {
    final router = Router();
    final controller = BusinessNotificationsController();

    router.get('/', controller.getNotifications);
    router.patch('/mark-all-read', controller.markAllAsRead);
    router.patch('/<id>/read', controller.markAsRead);

    return router;
  }
}
