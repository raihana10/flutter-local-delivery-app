import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../controllers/business_controller.dart';

class BusinessProductsRoutes {
  Handler get router {
    final router = Router();
    final controller = BusinessController();

    // PRODUITS
    router.get('/<id>/produits', controller.getProduits);
    router.post('/<id>/produits', controller.addProduit);
    router.patch('/<id>/produits/<pid>', controller.updateProduit);
    router.delete('/<id>/produits/<pid>', controller.deleteProduit);
    router.post('/<id>/produits/import', controller.importProduitsCsv);

    // PROMOTIONS ✨
    router.get('/<id>/promotions', controller.getPromotions);
    router.post('/<id>/promotions', controller.createPromotion);  // ← ENDPOINT PROMOTIONS
    router.delete('/<id>/promotions/<pid>', controller.deletePromotion);

    // STATS
    router.get('/<id>/stats', controller.getBusinessStats);

    // HOURS
    router.patch('/<id>/hours', controller.updateBusinessHours);

    // COMMANDES (déjà montées ailleurs mais on les rajoute ici aussi)
    router.get('/<id>/commandes', controller.getBusinessCommandes);
    router.patch('/<id>/commandes/<cid>/statut', controller.updateCommandeStatut);

    return router;
  }
}
