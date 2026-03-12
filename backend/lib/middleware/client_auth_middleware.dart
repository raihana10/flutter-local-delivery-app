import 'package:shelf/shelf.dart';

// Middleware to check x-client-id header for protected client routes
Middleware clientAuthMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Allow public routes if any
      final publicRoutes = ['/client/auth/login', '/client/auth/register'];
      if (publicRoutes.any((route) => request.url.path.startsWith(route.replaceFirst('/', '')))) {
        return innerHandler(request);
      }

      final clientId = request.headers['x-client-id'];
      if (clientId == null || clientId.isEmpty) {
        return Response(401, body: '{"error": "Unauthorized access. Missing x-client-id header"}',
            headers: {'content-type': 'application/json'});
      }

      // Pass the request if the client ID is present
      return innerHandler(request);
    };
  };
}
