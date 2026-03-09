import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/client/client_home_screen.dart';
import 'presentation/screens/livreur/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider()..init(),
      child: MaterialApp(
        title: 'LocalDelivery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthWrapper(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/client/home': (context) => const ClientHomeScreen(),
          '/livreur/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F0E8),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0f1e3d)),
              ),
            ),
          );
        }

        // Navigate based on auth state
        if (authProvider.isAuthenticated) {
          final user = authProvider.user;
          switch (user?.role.value) {
            case 'client':
              return const ClientHomeScreen();
            case 'livreur':
              return const DashboardScreen();
            case 'business':
              // TODO: Create Business Dashboard
              return const ClientHomeScreen(); // Temporary
            case 'super_admin':
              // TODO: Create Admin Dashboard
              return const ClientHomeScreen(); // Temporary
            default:
              return const AuthScreen();
          }
        }

        return const AuthScreen();
      },
    );
  }
}