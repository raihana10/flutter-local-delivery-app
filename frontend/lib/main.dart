import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/app_theme.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/presentation/screens/auth/auth_screen.dart';
import 'package:app/presentation/screens/auth/login_screen.dart';
import 'package:app/presentation/screens/auth/register_screen.dart';
import 'package:app/presentation/screens/livreur/dashboard_screen.dart';
import 'package:app/presentation/screens/client/client_home_screen.dart';
import 'package:app/presentation/screens/business/business_main_screen.dart';
import 'package:app/providers/product_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    return MaterialApp(
      title: 'LivrApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: authProvider.isAuthenticated 
        ? _getHomeScreen(authProvider.user?.role.value)
        : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/client/home': (context) => const ClientHomeScreen(),
        '/livreur/dashboard': (context) => const DashboardScreen(),
        '/business/dashboard': (context) => const BusinessMainScreen(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }

  Widget _getHomeScreen(String? role) {
    switch (role) {
      case 'client':
        return const ClientHomeScreen();
      case 'livreur':
        return const DashboardScreen();
      case 'business':
        return const BusinessMainScreen();
      default:
        return const AuthScreen();
    }
  }
}