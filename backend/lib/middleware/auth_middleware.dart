import 'dart:convert';
import 'package:shelf/shelf.dart';

// Universal Middleware to check authentication headers
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.url.path;

      // 1. Allow public routes
      final publicRoutes = [
        'admin/login',
        'client/auth/login',
        'client/auth/register',
        '', // Health check root
      ];

      if (publicRoutes.any((route) => path == route || path == '$route/')) {
        return innerHandler(request);
      }

      // 2. Client Routes Authentication
      if (path.startsWith('client/')) {
        final clientId = request.headers['x-client-id'];
        if (clientId == null || clientId.isEmpty) {
          return Response(
            401,
            body: jsonEncode({
              "error": "Unauthorized access. Missing x-client-id header",
            }),
            headers: {'content-type': 'application/json'},
          );
        }
        return innerHandler(request);
      }

      // 3. Admin Routes Authentication (Default)
      final adminId = request.headers['x-admin-id'];
      if (adminId == null || adminId.isEmpty) {
        return Response(
          403,
          body: jsonEncode({
            "error": "Unauthorized access. Missing x-admin-id header",
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}
