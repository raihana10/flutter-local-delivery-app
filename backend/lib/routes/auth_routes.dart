import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/auth_controller.dart';

class AuthRoutes {
  Handler get router {
    final router = Router();
    final authController = AuthController();

    router.post('/login', authController.login);
    router.post('/register', authController.register);

    return router;
  }
}
