import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/client/client_profile_controller.dart';

class ClientProfileRoutes {
  Handler get router {
    final router = Router();
    final controller = ClientProfileController();

    // Profile
    router.get('/profile', controller.getProfile);
    router.patch('/profile', controller.updateProfile);

    // Addresses
    router.get('/addresses', controller.getAddresses);
    router.post('/addresses', controller.addAddress);
    router.patch('/addresses/<id>', controller.updateAddress);
    router.delete('/addresses/<id>', controller.deleteAddress);

    return router;
  }
}
