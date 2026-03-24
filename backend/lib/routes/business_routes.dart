import 'package:shelf_router/shelf_router.dart';
import '../controllers/business_controller.dart';
import '../middleware/auth_middleware.dart';

class BusinessRoutes {
  final _controller = BusinessController();

  Router get router {
    final router = Router();

    router.get('/', _controller.getBusinesses);
    router.get('/<id>', _controller.getBusinessDetail);

    router.get('/<id>/produits', _controller.getProduits);
    router.post('/<id>/produits', _controller.addProduit);
    router.patch('/<id>/produits/<pid>', _controller.updateProduit);
    router.delete('/<id>/produits/<pid>', _controller.deleteProduit);
    router.post('/<id>/produits/import', _controller.importProduitsCsv);

    router.get('/<id>/commandes', _controller.getBusinessCommandes);
    router.patch(
      '/<id>/commandes/<cid>/statut',
      _controller.updateCommandeStatut,
    );

    router.patch('/<id>/hours', _controller.updateBusinessHours);

    router.get('/<id>/promotions', _controller.getPromotions);
    router.post('/<id>/promotions', _controller.createPromotion);
    router.delete('/<id>/promotions/<pid>', _controller.deletePromotion);

    router.get('/<id>/stats', _controller.getBusinessStats);

    return router;
  }
}
