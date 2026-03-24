import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/business/business_profile_controller.dart';

class BusinessProfileRoutes {
  Handler get router {
    final router = Router();
    final controller = BusinessProfileController();

    router.get('/', controller.getProfile);
    router.patch('/', controller.updateProfile);
    router.post('/addresses', controller.addAddress);
    router.get('/addresses', controller.getAddresses);
    router.patch('/addresses/<id>', controller.updateAddress);
    router.delete('/addresses/<id>', controller.deleteAddress);

    return router;
  }
}
