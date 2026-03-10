import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/business/business_main_screen.dart';
import 'presentation/screens/livreur/dashboard_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/client/client_home_screen.dart';
import 'providers/product_provider.dart';

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
    return MaterialApp(
      title:                    'LivrApp',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.lightTheme,
      darkTheme:                AppTheme.darkTheme,
      themeMode:                themeProvider.themeMode,
      initialRoute:             '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/client/home': (context) => const ClientHomeScreen(),
        '/livreur/dashboard': (context) => const DashboardScreen(),
        '/business/dashboard': (context) => const BusinessMainScreen(),
      },
    );
  }
}