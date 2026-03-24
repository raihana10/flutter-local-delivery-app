import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      // Replace localhost with your backend URL when deploying
      const apiUrl = String.fromEnvironment('API_URL',
          defaultValue: 'http://localhost:8084');

      final response = await dio.post(
        '$apiUrl/admin/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final adminId = data['id_admin'];

          // Save admin_id to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('x-admin-id', adminId as int);

          if (mounted) {
            Navigator.of(context)
                .pushReplacementNamed('/super_admin/dashboard');
          }
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Erreur de connexion';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['error'] ?? errorMessage;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isSmallScreen = screenWidth < 380;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? 320 : 430,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 24,
                          vertical: screenWidth < 600 ? 32 : 48,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.destructive,
                              AppColors.destructive.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.shieldAlert,
                                  size: 32,
                                  color: AppColors.destructive,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Administration',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.background,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Accès restreint au Superviseur',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.background.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 24,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email Admin',
                                  style: TextStyle(
                                    color: AppColors.foreground,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    const Icon(
                                      LucideIcons.mail,
                                      size: 18,
                                      color: AppColors.mutedForeground,
                                    ),
                                    TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: 'admin@local-delivery.com',
                                        contentPadding: const EdgeInsets.fromLTRB(
                                            40, 12, 16, 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.accent),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.card,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mot de passe',
                                  style: TextStyle(
                                    color: AppColors.foreground,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    const Positioned(
                                      left: 12,
                                      child: Icon(
                                        LucideIcons.lock,
                                        size: 18,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: !_showPassword,
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        contentPadding: const EdgeInsets.fromLTRB(
                                            40, 12, 48, 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(
                                              color: AppColors.accent),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.card,
                                      ),
                                    ),
                                    Positioned(
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                        child: Icon(
                                          _showPassword
                                              ? LucideIcons.eyeOff
                                              : LucideIcons.eye,
                                          size: 18,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.destructive,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: AppColors.background,
                                          strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Connexion Admin',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(LucideIcons.shieldCheck, size: 18),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pushReplacementNamed('/login');
                              },
                              child: const Text('Retour à la connexion standard',
                                  style:
                                      TextStyle(color: AppColors.mutedForeground)),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
