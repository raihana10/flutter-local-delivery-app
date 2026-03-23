import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/users_controller.dart';

class UsersRoutes {
  Handler get router {
    final router = Router();
    final usersController = UsersController();

    router.get('/clients', usersController.getClients);
    router.get('/livreurs', usersController.getLivreurs);
    router.get('/businesses', usersController.getBusinesses);
    router.get('/<id>', usersController.getUserDetail);

    // Toggles and Actions
    router.patch('/<id>/toggle', usersController.toggleUserStatus);
    router.patch('/livreurs/<id>/toggle', usersController.toggleUserStatus);
    router.patch('/businesses/<id>/toggle', usersController.toggleUserStatus);

    router.patch('/<id>/validate', usersController.validateUser);
    router.patch('/livreurs/<id>/validate', usersController.validateUser);
    router.patch('/businesses/<id>/validate', usersController.validateUser);

    // Soft delete
    router.delete('/<id>', usersController.deleteUser);

    return router;
  }
}
