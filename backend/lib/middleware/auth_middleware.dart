import 'package:shelf/shelf.dart';

// Middleware to check x-admin-id header for protected routes
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // The authentication route itself should not be protected
      if (request.url.path == 'admin/login') {
        return innerHandler(request);
      }

      final adminId = request.headers['x-admin-id'];
      if (adminId == null || adminId.isEmpty) {
        return Response(403, body: '{"error": "Unauthorized access. Missing x-admin-id header"}',
            headers: {'content-type': 'application/json'});
      }

      // Check if admin is currently active/valid?
      // Since memory flag is mentioned, for now the presence of the header is the auth mechanism. 
      return innerHandler(request);
    };
  };
}
