import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:app/data/models/auth_models.dart' as auth;
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';

enum UserRole { client, livreur, business }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1;
  UserRole? _selectedRole;
  bool _showPassword = false;

  // Common fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedCity;
  final _addressController = TextEditingController();

  // Livreur fields
  String? _vehicleType;
  final List<String> _vehicleTypes = [
    'Vélo',
    'Scooter / Moto',
    'Voiture',
    'Camionnette',
    'Piéton',
    'Autre'
  ];
  final _licenseNumberController = TextEditingController();

  // Documents Livreur
  File? _drivingLicenseImage;
  File? _idCardFrontImage;
  File? _idCardBackImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Business fields
  final _businessNameController = TextEditingController();
  String? _businessCategory;
  final _businessDescriptionController = TextEditingController();
  final _registreCommerceController = TextEditingController();

  // Documents Business
  File? _businessLogo;
  File? _commerceRegistrationDoc;

  // Photo de profil
  File? _profileImage;

  final List<String> cities = [
    'Tétouan',
    'Tanger',
    'Casablanca',
    'Rabat',
    'Fès',
    'Marrakech',
    'Agadir',
    'Oujda'
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _registreCommerceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required Function(File) onImagePicked,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        onImagePicked(File(pickedFile.path));
        _showSuccessSnackBar('Fichier téléchargé avec succès');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du téléchargement');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Validation basique
    if (_selectedRole == null) return;

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir les informations obligatoires');
      return;
    }

    if (_selectedRole == UserRole.livreur) {
      if (_vehicleType == null) {
        _showErrorSnackBar('Veuillez sélectionner un type de véhicule');
        return;
      }
    }

    final auth.UserRole mappedRole;
    switch (_selectedRole!) {
      case UserRole.client:
        mappedRole = auth.UserRole.client;
        break;
      case UserRole.livreur:
        mappedRole = auth.UserRole.livreur;
        break;
      case UserRole.business:
        mappedRole = auth.UserRole.business;
        break;
    }

    final request = auth.RegisterRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      nom: _fullNameController.text.trim(),
      numTl: _phoneController.text.trim(),
      role: mappedRole,
      businessType: _businessCategory,
      businessDescription: _businessDescriptionController.text.trim(),
      cni: _licenseNumberController.text.trim(),
    );

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(request);

    if (success) {
      if (mounted) {
        final role = authProvider.user?.role.value;
        switch (role) {
          case 'client':
            Navigator.of(context).pushReplacementNamed('/client/home');
            break;
          case 'livreur':
            Navigator.of(context).pushReplacementNamed('/livreur/dashboard');
            break;
          case 'business':
            Navigator.of(context).pushReplacementNamed('/business/dashboard');
            break;
          default:
            Navigator.of(context).pushReplacementNamed('/client/home');
        }
      }
    } else {
      if (mounted) {
        _showErrorSnackBar(
            authProvider.errorMessage ?? 'Erreur lors de l\'inscription');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentStep == 1 ? _buildStep1() : _buildStep23(),
    );
  }

  // STEP 1 - Role Selection
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero header
                Container(
                  padding: EdgeInsets.fromLTRB(32, 64, 32, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
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
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'LD',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.background,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choisissez votre profil',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.background.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Role selection buttons
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildRoleButton(
                        role: UserRole.client,
                        label: 'Client',
                        icon: LucideIcons.user,
                        description: 'Commander et se faire livrer',
                      ),
                      SizedBox(height: 12),
                      _buildRoleButton(
                        role: UserRole.livreur,
                        label: 'Livreur',
                        icon: LucideIcons.bike,
                        description: 'Livrer des commandes',
                      ),
                      SizedBox(height: 12),
                      _buildRoleButton(
                        role: UserRole.business,
                        label: 'Business',
                        icon: LucideIcons.store,
                        description: 'Gérer mon restaurant / commerce',
                      ),
                    ],
                  ),
                ),

                // Bottom link
                Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // STEP 2 & 3 - Common Info & Role-Specific Fields
  Widget _buildStep23() {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with back button
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 48, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_currentStep == 2) {
                                  _currentStep = 1;
                                  _selectedRole = null;
                                } else {
                                  _currentStep = 2;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.arrowLeft,
                                  size: 20,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentStep == 2
                                      ? 'Informations personnelles'
                                      : _getRoleSpecificTitle(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.foreground,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Étape ${_currentStep} sur 3 · ${_getRoleLabel()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentStep >= 2
                                    ? AppColors.accent
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentStep >= 3
                                    ? AppColors.accent
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Content based on current step
                _currentStep == 2 ? _buildStep2Content() : _buildStep3Content(),

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Content() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar avec upload
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                    image: _profileImage != null
                        ? DecorationImage(
                            image: FileImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImage == null
                      ? Icon(
                          LucideIcons.user,
                          size: 40,
                          color: AppColors.mutedForeground,
                        )
                      : null,
                ),
                GestureDetector(
                  onTap: () {
                    _pickImage(
                      onImagePicked: (file) {
                        setState(() {
                          _profileImage = file;
                        });
                      },
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Full Name
          _buildTextField(
            label: 'Nom complet',
            icon: LucideIcons.user,
            controller: _fullNameController,
            hint: 'Votre nom complet',
          ),
          SizedBox(height: 16),

          // Email
          _buildTextField(
            label: 'Email',
            icon: LucideIcons.mail,
            controller: _emailController,
            hint: 'votre@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),

          // Phone
          _buildTextField(
            label: 'Téléphone',
            icon: LucideIcons.phone,
            controller: _phoneController,
            hint: '+212 6XX XXX XXX',
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),

          // Password
          _buildPasswordField(),
          SizedBox(height: 16),

          // City
          _buildCityDropdown(),
          SizedBox(height: 16),

          // Address
          _buildTextField(
            label: 'Adresse',
            icon: LucideIcons.mapPin,
            controller: _addressController,
            hint: 'Votre adresse complète',
          ),
          SizedBox(height: 24),

          // Continue button
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 3;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(LucideIcons.arrowRight, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Content() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role-specific content
          if (_selectedRole == UserRole.client) ...[
            _buildInfoCard(
              icon: LucideIcons.user,
              title: 'Tout est prêt !',
              description:
                  'Votre profil client est complet. Vous pouvez commencer à explorer les restaurants et passer vos commandes.',
              iconColor: AppColors.accent,
            ),
          ] else if (_selectedRole == UserRole.livreur) ...[
            // Type de véhicule - Maintenant une vraie liste déroulante
            _buildVehicleDropdown(),
            SizedBox(height: 16),

            // Numéro de permis
            _buildTextField(
              label: 'Numéro de permis',
              icon: LucideIcons.fileText,
              controller: _licenseNumberController,
              hint: 'Numéro de permis de conduire',
            ),
            SizedBox(height: 16),

            // Permis de conduire
            _buildUploadZone(
              label: 'Permis de conduire',
              icon: LucideIcons.upload,
              description: _drivingLicenseImage != null
                  ? '✓ Permis téléchargé'
                  : 'Télécharger une photo',
              subtext: 'JPG, PNG · Max 5MB',
              file: _drivingLicenseImage,
              onTap: () {
                _pickImage(
                  onImagePicked: (file) {
                    setState(() {
                      _drivingLicenseImage = file;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16),

            // Carte d'identité recto
            _buildUploadZone(
              label: 'Carte d\'identité (Recto)',
              icon: LucideIcons.fileText,
              description: _idCardFrontImage != null
                  ? '✓ Recto téléchargé'
                  : 'Télécharger le recto',
              subtext: 'JPG, PNG · Max 5MB',
              file: _idCardFrontImage,
              onTap: () {
                _pickImage(
                  onImagePicked: (file) {
                    setState(() {
                      _idCardFrontImage = file;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16),

            // Carte d'identité verso
            _buildUploadZone(
              label: 'Carte d\'identité (Verso)',
              icon: LucideIcons.fileText,
              description: _idCardBackImage != null
                  ? '✓ Verso téléchargé'
                  : 'Télécharger le verso',
              subtext: 'JPG, PNG · Max 5MB',
              file: _idCardBackImage,
              onTap: () {
                _pickImage(
                  onImagePicked: (file) {
                    setState(() {
                      _idCardBackImage = file;
                    });
                  },
                );
              },
            ),
          ] else if (_selectedRole == UserRole.business) ...[
            // Logo du commerce
            _buildUploadZone(
              label: 'Logo du commerce',
              icon: LucideIcons.camera,
              description: _businessLogo != null
                  ? '✓ Logo téléchargé'
                  : 'Ajouter votre logo',
              subtext: 'JPG, PNG · Max 5MB',
              file: _businessLogo,
              onTap: () {
                _pickImage(
                  onImagePicked: (file) {
                    setState(() {
                      _businessLogo = file;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16),

            // Nom du commerce
            _buildTextField(
              label: 'Nom du commerce',
              icon: LucideIcons.store,
              controller: _businessNameController,
              hint: 'Nom de votre restaurant/commerce',
            ),
            SizedBox(height: 16),

            // Catégorie
            _buildCategoryDropdown(),
            SizedBox(height: 16),

            // Description
            _buildTextArea(
              label: 'Description',
              controller: _businessDescriptionController,
              hint: 'Décrivez votre commerce en quelques mots...',
            ),
            SizedBox(height: 16),

            // Registre de commerce
            _buildTextField(
              label: 'Registre de commerce',
              icon: LucideIcons.fileText,
              controller: _registreCommerceController,
              hint: 'Numéro RC',
            ),
            SizedBox(height: 16),

            // Justificatif RC
            _buildUploadZone(
              label: 'Justificatif RC',
              icon: LucideIcons.fileText,
              description: _commerceRegistrationDoc != null
                  ? '✓ Document téléchargé'
                  : 'Télécharger le document',
              subtext: 'PDF, JPG · Max 10MB',
              file: _commerceRegistrationDoc,
              onTap: () {
                _pickImage(
                  onImagePicked: (file) {
                    setState(() {
                      _commerceRegistrationDoc = file;
                    });
                  },
                );
              },
            ),
          ],

          SizedBox(height: 24),

          // Submit button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: authProvider.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Chargement...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedRole == UserRole.client ? 'Commencer' : 'Créer mon compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, size: 18),
                        ],
                      ),
              );
            },
          ),

          SizedBox(height: 16),

          // Terms text
          Text(
            'En créant un compte, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String label,
    required IconData icon,
    required String description,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _currentStep = 2;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.accent, width: 2)
              : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color:
                    isSelected ? AppColors.primary : AppColors.mutedForeground,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.background
                          : AppColors.foreground,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.background.withOpacity(0.7)
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.arrowRight,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: textAlign,
              decoration: InputDecoration(
                hintText: hint,
                contentPadding: EdgeInsets.fromLTRB(40, 12, 16, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
                filled: true,
                fillColor: AppColors.card,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
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
                contentPadding: EdgeInsets.fromLTRB(40, 12, 48, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.accent),
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
                  _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ville',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.card,
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: SizedBox(),
            value: _selectedCity,
            hint: Row(
              children: [
                Icon(LucideIcons.mapPin,
                    size: 18, color: AppColors.mutedForeground),
                SizedBox(width: 8),
                Text(
                  'Choisir votre ville',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ],
            ),
            items: cities
                .map(
                  (city) => DropdownMenuItem(
                    value: city,
                    child: Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(city),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de véhicule',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _vehicleType != null ? AppColors.accent : AppColors.border,
              width: _vehicleType != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.card,
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: SizedBox(),
            value: _vehicleType,
            hint: Row(
              children: [
                Icon(LucideIcons.bike,
                    size: 18, color: AppColors.mutedForeground),
                SizedBox(width: 8),
                Text(
                  'Choisir le type de véhicule',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ],
            ),
            items: _vehicleTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        _getVehicleIcon(type),
                        SizedBox(width: 8),
                        Text(
                          type,
                          style: TextStyle(
                            fontWeight: _vehicleType == type
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _vehicleType = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _getVehicleIcon(String vehicleType) {
    IconData iconData;
    Color iconColor = AppColors.accent;

    switch (vehicleType) {
      case 'Vélo':
        iconData = LucideIcons.bike;
        break;
      case 'Scooter / Moto':
        iconData = LucideIcons.bike;
        break;
      case 'Voiture':
        iconData = LucideIcons.car;
        break;
      case 'Camionnette':
        iconData = LucideIcons.truck;
        break;
      case 'Piéton':
        iconData = LucideIcons.footprints;
        break;
      default:
        iconData = Icons.help;
        iconColor = AppColors.mutedForeground;
    }

    return Icon(iconData, size: 18, color: iconColor);
  }

  Widget _buildCategoryDropdown() {
    final categories = {
      'restaurant': '🍽️ Restaurant',
      'cafe': '☕ Café & Pâtisserie',
      'epicerie': '🛒 Épicerie',
      'pharmacie': '💊 Pharmacie',
      'boulangerie': '🥖 Boulangerie',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _businessCategory != null
                  ? AppColors.accent
                  : AppColors.border,
              width: _businessCategory != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.card,
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: SizedBox(),
            value: _businessCategory,
            hint: Text(
              'Type de commerce',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            items: categories.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _businessCategory = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppColors.accent),
            ),
            filled: true,
            fillColor: AppColors.card,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadZone({
    required String label,
    required IconData icon,
    required String description,
    required String subtext,
    File? file,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: file != null ? Colors.green : AppColors.border,
                width: file != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
              color: file != null
                  ? Colors.green.withOpacity(0.05)
                  : AppColors.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: file != null
                        ? Colors.green.withOpacity(0.1)
                        : AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    file != null ? Icons.check_circle : icon,
                    size: 20,
                    color:
                        file != null ? Colors.green : AppColors.mutedForeground,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: file != null
                              ? Colors.green
                              : AppColors.foreground,
                          fontWeight: file != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (file == null) ...[
                        SizedBox(height: 4),
                        Text(
                          subtext,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: iconColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRoleLabel() {
    switch (_selectedRole) {
      case UserRole.client:
        return 'Client';
      case UserRole.livreur:
        return 'Livreur';
      case UserRole.business:
        return 'Business';
      default:
        return '';
    }
  }

  String _getRoleSpecificTitle() {
    switch (_selectedRole) {
      case UserRole.client:
        return 'Préférences';
      case UserRole.livreur:
        return 'Informations livreur';
      case UserRole.business:
        return 'Votre commerce';
      default:
        return '';
    }
  }
}
