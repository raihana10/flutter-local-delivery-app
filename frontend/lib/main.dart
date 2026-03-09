import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/app_theme.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/presentation/screens/client/client_home_screen.dart';

import 'package:app/core/providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      home:                     const ClientHomeScreen(),
    );
  }
}