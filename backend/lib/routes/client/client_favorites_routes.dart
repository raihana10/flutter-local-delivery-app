import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/client/client_favorites_controller.dart';

class ClientFavoritesRoutes {
  final ClientFavoritesController _controller = ClientFavoritesController();

  Handler get router {
    final router = Router();

    // /client/favorites
    router.get('/', _controller.getFavorites);
    router.post('/', _controller.addFavorite);
    router.delete('/<idBusiness>', _controller.removeFavorite);

    return router;
  }
}
