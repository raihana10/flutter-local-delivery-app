import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/dashboard_controller.dart';

class DashboardRoutes {
  Handler get router {
    final router = Router();
    final dashboardController = DashboardController();

    router.get('/kpis', dashboardController.getKPIs);
    router.get('/chart', dashboardController.getChartData);
    router.get('/alerts', dashboardController.getAlerts);
    router.get('/livreurs/positions', dashboardController.getLiveDrivers);

    return router;
  }
}
