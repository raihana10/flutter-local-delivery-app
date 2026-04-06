import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/auth_models.dart';
import '../../../core/constants/app_colors.dart';
import 'verify_email_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cniController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessTypeController = TextEditingController();
  String? _selectedVehicleType;
  List<String> _documentPaths = [];

  bool _isLogin = true;
  UserRole _selectedRole = UserRole.client;
  String? _selectedSexe;
  String? _selectedBusinessType;
  DateTime? _selectedDateNaissance;
  bool _obscurePassword = true;
  bool _isLoadingGoogle = false;

  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _formAnimation;
  late AnimationController _roleSelectionController;
  late Animation<double> _roleSelectionAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _roleSelectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _formAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));

    _roleSelectionAnimation = CurvedAnimation(
      parent: _roleSelectionController,
      curve: Curves.easeInOut,
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _phoneController.dispose();
    _cniController.dispose();
    _businessDescriptionController.dispose();
    _businessTypeController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _roleSelectionController.dispose();
    super.dispose();
  }

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _documentPaths
              .addAll(result.files.map((file) => file.path!).toList());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} document(s) importé(s)'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'importation: $e'),
          backgroundColor: AppColors.destructive,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _documentPaths.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        _navigateToHome();
      }
    } else {
      // Create register request with role-specific data
      final request = RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nomController.text.trim(),
        numTl: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _selectedRole,
        sexe: _selectedSexe,
        dateNaissance: _selectedDateNaissance,
        cni: _selectedRole == UserRole.livreur
            ? _cniController.text.trim()
            : null,
        businessType:
            _selectedRole == UserRole.business ? _selectedBusinessType : null,
        businessDescription: _selectedRole == UserRole.business
            ? _businessDescriptionController.text.trim()
            : null,
        documentsValidation: _documentPaths.isNotEmpty ? _documentPaths.join(',') : null,
      );

      final registerResult = await authProvider.register(request);

      if (registerResult.success && mounted) {
        if (registerResult.verificationRequired) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: request.email, password: request.password),
            ),
          );
        } else {
          _navigateToHome();
        }
      }
    }
  }

  void _navigateToHome() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    switch (user?.role.value) {
      case 'client':
        Navigator.of(context).pushReplacementNamed('/client/home');
        break;
      case 'livreur':
        Navigator.of(context).pushReplacementNamed('/livreur/dashboard');
        break;
      case 'business':
        Navigator.of(context).pushReplacementNamed('/business/dashboard');
        break;
      case 'super_admin':
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      default:
        Navigator.of(context).pushReplacementNamed('/client/home');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoadingGoogle = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ok = await authProvider.signInWithGoogle();
      if (!mounted) return;
      if (ok) {
        _navigateToHome();
      } else if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion Google: $error'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGoogle = false;
        });
      }
    }
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      // Reset role-specific fields when changing role
      _selectedSexe = null;
      _selectedDateNaissance = null;
      _cniController.clear();
      _businessDescriptionController.clear();
      _businessTypeController.clear();
    });
    _roleSelectionController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Animated Logo
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delivery_dining,
                                color: AppColors.accent,
                                size: 60,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'LocalDelivery',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: -0.8,
                                shadows: [
                                  Shadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isLogin
                                    ? 'Connectez-vous à votre compte'
                                    : 'Rejoignez notre communauté',
                                key: ValueKey(_isLogin),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.mutedForeground,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Animated Form Container
                AnimatedBuilder(
                  animation: _formAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _formAnimation.value,
                      child: Opacity(
                        opacity: _formController.value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role Selection (only for registration)
                              if (!_isLogin) ...[
                                Text(
                                  'Je souhaite m\'inscrire en tant que...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.foreground,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                AnimatedBuilder(
                                  animation: _roleSelectionAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _roleSelectionAnimation.value,
                                      child: Transform.scale(
                                        scale: 0.95 +
                                            (_roleSelectionAnimation.value *
                                                0.05),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _buildRoleChip(
                                                  UserRole.client,
                                                  'Client',
                                                  Icons.person),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildRoleChip(
                                                  UserRole.livreur,
                                                  'Livreur',
                                                  Icons.delivery_dining),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                AnimatedBuilder(
                                  animation: _roleSelectionAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _roleSelectionAnimation.value,
                                      child: Transform.scale(
                                        scale: 0.95 +
                                            (_roleSelectionAnimation.value *
                                                0.05),
                                        child: _buildRoleChip(UserRole.business,
                                            'Commerce', Icons.business,
                                            isFullWidth: true),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                              ],

                              // Common Fields
                              _buildTextField(
                                controller: _nomController,
                                label: 'Nom complet',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le nom est requis';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Le nom doit contenir au moins 3 caractères';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _emailController,
                                label: 'Adresse email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'L\'email est requis';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Veuillez entrer un email valide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                icon: Icons.lock,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.mutedForeground,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Le mot de passe est requis';
                                  }
                                  if (!_isLogin && value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  return null;
                                },
                              ),

                              // Role-specific fields
                              if (!_isLogin) ...[
                                const SizedBox(height: 20),
                                _buildRoleSpecificFields(),
                              ],

                              const SizedBox(height: 40),

                              // Submit button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return ElevatedButton(
                                    onPressed:
                                        authProvider.isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.accent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor:
                                          AppColors.primary.withOpacity(0.3),
                                    ),
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      AppColors.accent),
                                            ),
                                          )
                                        : Text(
                                            _isLogin
                                                ? 'Se connecter'
                                                : 'Créer mon compte',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Google Sign-In button
                              Container(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoadingGoogle
                                      ? null
                                      : _signInWithGoogle,
                                  icon: _isLoadingGoogle
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary),
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/google_logo.png',
                                          height: 20,
                                          width: 20,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(Icons.search,
                                                color: AppColors.primary,
                                                size: 20);
                                          },
                                        ),
                                  label: Text(
                                    'Continuer avec Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    side: BorderSide(
                                        color: AppColors.border, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: AppColors.card,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Error message
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  if (authProvider.errorMessage != null) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.destructive
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.destructive
                                                .withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: AppColors.destructive,
                                              size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              authProvider.errorMessage!,
                                              style: TextStyle(
                                                color: AppColors.destructive,
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 20),
                                            onPressed: () =>
                                                authProvider.clearError(),
                                            color: AppColors.destructive,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Toggle login/register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Pas encore de compte ?' : 'Déjà un compte ?',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                          Provider.of<AuthProvider>(context, listen: false)
                              .clearError();
                        });
                        if (!_isLogin) {
                          _roleSelectionController.forward(from: 0.0);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                        _isLogin ? 'S\'inscrire' : 'Se connecter',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label, IconData icon,
      {bool isFullWidth = false}) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => _onRoleChanged(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.mutedForeground,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? AppColors.accent : AppColors.mutedForeground,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: TextStyle(
        color: AppColors.foreground,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(
            icon,
            color: AppColors.mutedForeground,
            size: 22,
          ),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.destructive, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.destructive, width: 2),
        ),
        errorStyle: TextStyle(
          color: AppColors.destructive,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      validator: validator,
    );
  }

  Widget _buildRoleSpecificFields() {
    switch (_selectedRole) {
      case UserRole.client:
        return _buildClientFields();
      case UserRole.livreur:
        return _buildLivreurFields();
      case UserRole.business:
        return _buildBusinessFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Genre',
                icon: Icons.wc,
                value: _selectedSexe,
                items: const [
                  DropdownMenuItem(value: 'homme', child: Text('Homme')),
                  DropdownMenuItem(value: 'femme', child: Text('Femme')),
                ],
                onChanged: (value) => setState(() => _selectedSexe = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Date de naissance',
                icon: Icons.calendar_today,
                value: _selectedDateNaissance,
                onChanged: (date) =>
                    setState(() => _selectedDateNaissance = date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone (optionnel)',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildLivreurFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TEST VISIBLE - Conteneur rouge pour confirmer que la méthode est appelée
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Text(
            '🔴 TEST: Vous êtes bien en mode LIVREUR - Les nouvelles fonctionnalités sont ci-dessous',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Informations du livreur',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Genre',
                icon: Icons.wc,
                value: _selectedSexe,
                items: const [
                  DropdownMenuItem(value: 'homme', child: Text('Homme')),
                  DropdownMenuItem(value: 'femme', child: Text('Femme')),
                ],
                onChanged: (value) => setState(() => _selectedSexe = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Date de naissance',
                icon: Icons.calendar_today,
                value: _selectedDateNaissance,
                onChanged: (date) =>
                    setState(() => _selectedDateNaissance = date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le téléphone est requis pour les livreurs';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Type de véhicule
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚗 Type de véhicule',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdownField(
                label: 'Type de véhicule',
                icon: Icons.motorcycle,
                value: _selectedVehicleType,
                items: const [
                  DropdownMenuItem(value: 'moto', child: Text('🏍️ Moto')),
                  DropdownMenuItem(value: 'scooter', child: Text('🛵 Scooter')),
                  DropdownMenuItem(value: 'voiture', child: Text('🚗 Voiture')),
                  DropdownMenuItem(value: 'velo', child: Text('🚲 Vélo')),
                  DropdownMenuItem(
                      value: 'camionnette', child: Text('🚐 Camionnette')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedVehicleType = value),
                validator: (value) {
                  if (value == null || value!.isEmpty) {
                    return 'Le type de véhicule est requis';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Importation de documents
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📄 Documents requis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 12),

              // Documents upload area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Importez vos documents (CNI, permis, etc.)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickDocuments,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Importer',
                              style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Documents list
                    if (_documentPaths.isNotEmpty) ...[
                      Text(
                        'Documents importés:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._documentPaths.asMap().entries.map((entry) {
                        final fileName = entry.value.split('/').last;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.foreground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeDocument(entry.key),
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.destructive,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildTextField(
          controller: _cniController,
          label: 'Numéro CNI',
          icon: Icons.badge,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le numéro CNI est requis';
            }
            if (value.trim().length < 5) {
              return 'Numéro CNI invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBusinessFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du commerce',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Type de commerce',
          icon: Icons.business,
          value: _selectedBusinessType,
          items: const [
            DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
            DropdownMenuItem(value: 'super-marche', child: Text('Supermarché')),
            DropdownMenuItem(value: 'pharmacie', child: Text('Pharmacie')),
          ],
          onChanged: (value) => setState(() => _selectedBusinessType = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le type de commerce est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _businessDescriptionController,
          label: 'Description du commerce',
          icon: Icons.description,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est requise';
            }
            if (value.trim().length < 10) {
              return 'La description doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone du commerce',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le téléphone est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: AppColors.foreground,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(
            icon,
            color: AppColors.mutedForeground,
            size: 22,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.destructive, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.destructive, width: 2),
        ),
        errorStyle: TextStyle(
          color: AppColors.destructive,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      dropdownColor: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              value ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: AppColors.accent,
                  surface: AppColors.card,
                  onSurface: AppColors.foreground,
                ),
                dialogBackgroundColor: AppColors.card,
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: value != null
                ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                : null,
          ),
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                icon,
                color: AppColors.mutedForeground,
                size: 22,
              ),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_drop_down,
                color: AppColors.mutedForeground,
                size: 24,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.destructive, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.destructive, width: 2),
            ),
            errorStyle: TextStyle(
              color: AppColors.destructive,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: 'JJ/MM/AAAA',
            hintStyle: TextStyle(
              color: AppColors.mutedForeground.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
