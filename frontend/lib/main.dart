import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/app_theme.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/presentation/screens/auth/auth_screen.dart';
import 'package:app/presentation/screens/auth/login_screen.dart';
import 'package:app/presentation/screens/auth/register_screen.dart';
import 'package:app/presentation/screens/livreur/dashboard_screen.dart';
import 'package:app/presentation/screens/client/client_home_screen.dart';
import 'package:app/presentation/screens/business/business_main_screen.dart';
import 'package:app/presentation/screens/super_admin/super_admin_main_screen.dart';
import 'package:app/presentation/screens/super_admin/super_admin_login_screen.dart';
import 'package:app/providers/product_provider.dart';
import 'package:app/core/providers/client_data_provider.dart';

import 'package:app/core/providers/livreur_dashboard_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to load .env, but don't crash if it doesn't exist yet (for the instructions to pass)
  try {
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase if envs are present
    if (dotenv.env['SUPABASE_URL'] != null && dotenv.env['SUPABASE_URL'] != 'YOUR_SUPABASE_URL') {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
    }
  } catch (e) {
    debugPrint("Please setup .env file with SUPABASE_URL and SUPABASE_ANON_KEY");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProxyProvider<AuthProvider, ClientDataProvider>(
          create: (context) => ClientDataProvider(authProvider: context.read<AuthProvider>()),
          update: (context, auth, previous) => previous ?? ClientDataProvider(authProvider: auth),
        ),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LivreurDashboardProvider>(
          create: (context) => LivreurDashboardProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => previous ?? LivreurDashboardProvider(auth),
        ),
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

    return MaterialApp(
      title: 'LivrApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const RoleRouter(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/client/home': (context) => const ClientHomeScreen(),
        '/livreur/dashboard': (context) => const DashboardScreen(),
        '/business/dashboard': (context) => const BusinessMainScreen(),
        '/super_admin/dashboard': (context) => const SuperAdminMainScreen(),
        '/super_admin/login': (context) => const SuperAdminLoginScreen(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        final role = authProvider.user?.role.value;
        if (role == null) {
          // Si le rôle n'est pas encore chargé (ou utilisateur non trouvé dans la base)
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        switch (role) {
          case 'client':
            return const ClientHomeScreen();
          case 'livreur':
            return const DashboardScreen();
          case 'business':
            return const BusinessMainScreen();
          case 'super_admin':
            return const SuperAdminMainScreen();
          default:
            return const AuthScreen();
        }
      },
    );
  }
}
