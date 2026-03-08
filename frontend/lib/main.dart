import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'presentation/screens/livreur/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:        'LivrApp',
      debugShowCheckedModeBanner: false,
      theme:        AppTheme.theme,
      home:         const DashboardScreen(),
    );
  }
}