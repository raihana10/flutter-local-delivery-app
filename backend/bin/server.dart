import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';

import '../lib/supabase/supabase_client.dart';
import '../lib/middleware/auth_middleware.dart';

import '../lib/routes/auth_routes.dart';
import '../lib/routes/dashboard_routes.dart';
import '../lib/routes/users_routes.dart';
import '../lib/routes/commandes_routes.dart';
import '../lib/routes/paiements_routes.dart';
import '../lib/routes/stats_routes.dart';
import '../lib/routes/notifications_routes.dart';


void main(List<String> args) async {
  // 1. Initialize Supabase
  try {
    SupabaseConfig.initialize();
  } catch (e) {
    print('Failed to initialize Supabase: $e');
    exit(1);
  }

  // 2. Setup Router
  final router = Router();

  // Root endpoint for simple health check
  router.get('/', (Request request) {
    return Response.ok('LocalDelivery Super Admin API is running.');
  });

  // Mount API modules
  router.mount('/admin', AuthRoutes().router);
  router.mount('/admin/dashboard', DashboardRoutes().router);
  router.mount('/admin/users', UsersRoutes().router);
  router.mount('/admin/commandes', CommandesRoutes().router);
  router.mount('/admin/paiements', PaiementsRoutes().router);
  router.mount('/admin/stats', StatsRoutes().router);
  router.mount('/admin/notifications', NotificationsRoutes().router);

  // 3. Assemble Pipeline
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(authMiddleware()) // Protect all routes under /admin except /admin/login (handled in middleware)
      .addHandler(router);

  // 4. Start Server
  final env = DotEnv()..load();
  final port = int.parse(Platform.environment['PORT'] ?? '8084');

  final server = await serve(pipeline, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');
}
