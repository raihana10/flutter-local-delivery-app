import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/auth_models.dart' as auth;
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'verify_email_screen.dart';

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
  bool _isLoadingGoogle = false;

  // Common fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  LatLng? _selectedLocation;
  String? _selectedCity = 'Tétouan'; // ← AJOUTER avec valeur par défaut
  final MapController _mapController = MapController();

  // Client fields
  String? _selectedSexe;
  DateTime? _selectedDateNaissance;

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
  String? _drivingLicenseUrl;
  String? _idCardFrontUrl;
  String? _idCardBackUrl;

  XFile? _drivingLicenseFile;
  XFile? _idCardFrontFile;
  XFile? _idCardBackFile;
  final ImagePicker _imagePicker = ImagePicker();

  // Business fields
  String? _businessCategory;
  final _businessDescriptionController = TextEditingController();
  final _registreCommerceController = TextEditingController();

  // Documents Business
  String? _businessLogoUrl;
  String? _commerceRegistrationUrl;

  XFile? _businessLogoFile;
  XFile? _commerceRegistrationFile;

  // Photo de profil
  XFile? _profileImage;
  String? _profileImageUrl;

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
    _mapController.dispose();
    _licenseNumberController.dispose();
    _businessDescriptionController.dispose();
    _registreCommerceController.dispose();
    super.dispose();
  }

  Future<String?> _uploadToSupabase(XFile file, String folder) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$folder/$fileName';

      await Supabase.instance.client.storage
          .from('alae')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

      // Stocker le chemin relatif (court) : plusieurs URLs complètes dépassent souvent VARCHAR(255).
      return path;
    } catch (e) {
      print('UPLOAD ERROR: $e');
      throw e;
    }
  }

  Future<void> _pickAndUpload({
    required Function(XFile file, String? url) onDone,
    required String folder,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _showSuccessSnackBar('Fichier sélectionné, upload en cours...');

        final storagePath = await _uploadToSupabase(pickedFile, folder);

        if (storagePath != null) {
          onDone(pickedFile, storagePath);
          _showSuccessSnackBar('Fichier uploadé avec succès ✅');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur d\'upload : ${e.toString()}');
    }
  }

  Future<void> _pickImage({
    required Function(XFile) onImagePicked,
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
        onImagePicked(pickedFile);
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

  bool _needsDrivingLicense() {
    // Vélo et Piéton n'ont pas besoin de permis de conduire
    if (_vehicleType == null) return true; // Par défaut, on demande le permis
    return !['Vélo', 'Piéton'].contains(_vehicleType);
  }

  Future<void> _signInWithGoogleAsClient() async {
    setState(() => _isLoadingGoogle = true);
    try {
      final auth = context.read<AuthProvider>();
      final ok = await auth.signInWithGoogle();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacementNamed('/client/home');
      } else if (auth.errorMessage != null) {
        _showErrorSnackBar(auth.errorMessage!);
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
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
    if (_selectedRole == null) return;

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir les informations obligatoires');
      return;
    }

    if (_selectedLocation == null) {
      _showErrorSnackBar('Veuillez choisir votre position sur la carte');
      return;
    }

    if (_selectedRole == UserRole.livreur) {
      if (_vehicleType == null) {
        _showErrorSnackBar('Veuillez sélectionner un type de véhicule');
        return;
      }
      // Ne demander le permis que si nécessaire
      if (_needsDrivingLicense() && (_drivingLicenseUrl == null || _idCardFrontUrl == null || _idCardBackUrl == null)) {
        _showErrorSnackBar('Veuillez uploader tous les documents requis');
        return;
      }
      // Pour vélo/piéton, seulement la CNI est requise
      if (!_needsDrivingLicense() && (_idCardFrontUrl == null || _idCardBackUrl == null)) {
        _showErrorSnackBar('Veuillez uploader votre carte d\'identité');
        return;
      }
    }

    if (_selectedRole == UserRole.business) {
      if (_businessCategory == null) {
        _showErrorSnackBar('Veuillez sélectionner une catégorie');
        return;
      }
      if (_commerceRegistrationUrl == null) {
        _showErrorSnackBar('Veuillez joindre le justificatif du registre de commerce');
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

    final docsUrl = [
      if (_drivingLicenseUrl != null) _drivingLicenseUrl!,
      if (_idCardFrontUrl != null) _idCardFrontUrl!,
      if (_idCardBackUrl != null) _idCardBackUrl!,
    ].join(',');

    final request = auth.RegisterRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      nom: _fullNameController.text.trim(),
      numTl: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      role: mappedRole,
      
      // Client & Livreur
      sexe: _selectedSexe,
      dateNaissance: _selectedDateNaissance,
      
      // Livreur
      cni: _licenseNumberController.text.trim().isEmpty ? null : _licenseNumberController.text.trim(),
      documentsValidation: _selectedRole == UserRole.livreur
          ? [
              if (_idCardFrontUrl != null) _idCardFrontUrl!,
              if (_idCardBackUrl != null) _idCardBackUrl!,
              if (_needsDrivingLicense() && _drivingLicenseUrl != null) _drivingLicenseUrl!,
            ].join(',')
          : _commerceRegistrationUrl,
      
      // Business
      businessType: _businessCategory,
      businessDescription: _businessDescriptionController.text.trim().isEmpty
          ? null
          : _businessDescriptionController.text.trim(),
      profileImageUrl: _businessLogoUrl,
      
      // Adresse
      ville: _selectedCity,
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
    );

    print('📤 REGISTER REQUEST: ${request.toJson()}'); // ← debug crucial

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.register(request);

    if (result.success && mounted) {
      if (result.verificationRequired == true) {
        // Redirect to email verification
// ✅ APRÈS
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => VerifyEmailScreen(
      email: request.email,
      password: request.password, // ✅ passe le password
    ),
  ),
);
      } else {
        print('REGISTERED ROLE: ${result.role}');
        
        final role = result.role;
        if (role == 'client') {
          Navigator.of(context).pushReplacementNamed('/client/home');
        } else if (role == 'livreur' || role == 'business') {
          // Redirect to pending approval
          Navigator.of(context).pushReplacementNamed('/pending-approval');
        } else {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } else if (mounted) {
      _showErrorSnackBar(
        authProvider.errorMessage ?? 'Erreur lors de l\'inscription'
      );
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
                        label: 'Commerce',
                        icon: LucideIcons.store,
                        description: 'Gérer mon restaurant / commerce',
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'ou',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed:
                            _isLoadingGoogle ? null : _signInWithGoogleAsClient,
                        icon: _isLoadingGoogle
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.login, size: 20, color: AppColors.foreground),
                        label: Text(
                          'Continuer avec Google (compte client)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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
          // ✅ Photo de profil uniquement pour client et livreur
          if (_selectedRole != UserRole.business) ...[            
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
                              image: kIsWeb
                                  ? NetworkImage(_profileImage!.path)
                                  : FileImage(File(_profileImage!.path)) as ImageProvider,
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
                      _pickAndUpload(
                        folder: 'users/avatars',
                        onDone: (file, url) {
                          setState(() {
                            _profileImage = file;
                            _profileImageUrl = url;
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
          ],

          // Full Name
          _buildTextField(
            label: _selectedRole == UserRole.business
                ? 'Nom du commerce'
                : 'Nom complet',
            hint: _selectedRole == UserRole.business
                ? 'Ex: Pizza Roma, Pharmacie Centrale...'
                : 'Votre nom complet',
            icon: _selectedRole == UserRole.business
                ? LucideIcons.store
                : LucideIcons.user,
            controller: _fullNameController,
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

          // Location Picker
          _buildLocationPicker(),
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
            // Sexe
            _buildSexeDropdown(),
            SizedBox(height: 16),
            // Date de naissance
            _buildDatePicker(),
            SizedBox(height: 16),
            // Message informatif
            _buildInfoCard(
              icon: LucideIcons.user,
              title: 'Tout est prêt !',
              description: 'Votre profil est complet. Vous pouvez commencer à explorer.',
              iconColor: AppColors.accent,
            ),
          ] else if (_selectedRole == UserRole.livreur) ...[
            // Sexe
            _buildSexeDropdown(),
            SizedBox(height: 16),

            // Date de naissance
            _buildDatePicker(),
            SizedBox(height: 16),

            // Type de véhicule - Maintenant une vraie liste déroulante
            _buildVehicleDropdown(),
            SizedBox(height: 16),

            // Numéro de permis (conditionnel)
            if (_needsDrivingLicense()) ...[
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
                description: _drivingLicenseUrl != null ? '✓ Permis uploadé' : 'Télécharger une photo',
                subtext: 'JPG, PNG · Max 5MB',
                isUploaded: _drivingLicenseUrl != null,
                onTap: () => _pickAndUpload(
                  folder: 'livreurs/permis',
                  onDone: (file, url) => setState(() {
                    _drivingLicenseFile = file;
                    _drivingLicenseUrl = url;
                  }),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Carte d'identité recto
            _buildUploadZone(
              label: 'Carte d\'identité (Recto)',
              icon: LucideIcons.fileText,
              description: _idCardFrontUrl != null ? '✓ Recto uploadé' : 'Télécharger le recto',
              subtext: 'JPG, PNG · Max 5MB',
              isUploaded: _idCardFrontUrl != null,
              onTap: () => _pickAndUpload(
                folder: 'livreurs/cni',
                onDone: (file, url) => setState(() {
                  _idCardFrontFile = file;
                  _idCardFrontUrl = url;
                }),
              ),
            ),
            SizedBox(height: 16),

            // Carte d'identité verso
            _buildUploadZone(
              label: 'Carte d\'identité (Verso)',
              icon: LucideIcons.fileText,
              description: _idCardBackUrl != null ? '✓ Verso uploadé' : 'Télécharger le verso',
              subtext: 'JPG, PNG · Max 5MB',
              isUploaded: _idCardBackUrl != null,
              onTap: () => _pickAndUpload(
                folder: 'livreurs/cni',
                onDone: (file, url) => setState(() {
                  _idCardBackFile = file;
                  _idCardBackUrl = url;
                }),
              ),
            ),
          ] else if (_selectedRole == UserRole.business) ...[
            // Logo du commerce
            _buildUploadZone(
              label: 'Logo du commerce',
              icon: LucideIcons.camera,
              description: _businessLogoUrl != null ? '✓ Logo uploadé' : 'Ajouter votre logo',
              subtext: 'JPG, PNG · Max 5MB',
              isUploaded: _businessLogoUrl != null,
              onTap: () => _pickAndUpload(
                folder: 'businesses/logos',
                onDone: (file, url) => setState(() {
                  _businessLogoFile = file;
                  _businessLogoUrl = url;
                }),
              ),
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
              description: _commerceRegistrationUrl != null ? '✓ Document uploadé' : 'Télécharger le document',
              subtext: 'PDF, JPG · Max 10MB',
              isUploaded: _commerceRegistrationUrl != null,
              onTap: () => _pickAndUpload(
                folder: 'businesses/documents',
                onDone: (file, url) => setState(() {
                  _commerceRegistrationFile = file;
                  _commerceRegistrationUrl = url;
                }),
              ),
            ),
          ],

          SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _handleSubmit,
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
                  _selectedRole == UserRole.client
                      ? 'Commencer'
                      : 'Créer mon compte',
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

  Widget _buildSexeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sexe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.card,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedSexe,
              hint: Text('Choisir', style: TextStyle(color: AppColors.mutedForeground)),
              items: [
                DropdownMenuItem(value: 'homme', child: Text('👨 Homme')),
                DropdownMenuItem(value: 'femme', child: Text('👩 Femme')),
              ],
              onChanged: (value) => setState(() => _selectedSexe = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date de naissance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().subtract(Duration(days: 365 * 16)),
            );
            if (date != null) setState(() => _selectedDateNaissance = date);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.card,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, size: 18, color: AppColors.mutedForeground),
                SizedBox(width: 12),
                Text(
                  _selectedDateNaissance != null
                      ? '${_selectedDateNaissance!.day.toString().padLeft(2,'0')}/${_selectedDateNaissance!.month.toString().padLeft(2,'0')}/${_selectedDateNaissance!.year}'
                      : 'JJ/MM/AAAA',
                  style: TextStyle(
                    color: _selectedDateNaissance != null
                        ? AppColors.foreground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation (Position sur la carte)',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedLocation == null ? Colors.red.withOpacity(0.5) : AppColors.border,
              width: _selectedLocation == null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.hardEdge,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(35.5785, -5.3684),
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_selectedLocation == null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Veuillez cliquer sur la carte pour choisir votre position exacte.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
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
      'super-marche': '🛒 Supermarché',
      'pharmacie': '💊 Pharmacie',
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
    required bool isUploaded,
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
                color: isUploaded ? Colors.green : AppColors.border,
                width: isUploaded ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
              color: isUploaded
                  ? Colors.green.withOpacity(0.05)
                  : AppColors.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? Colors.green.withOpacity(0.1)
                        : AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check_circle : icon,
                    size: 20,
                    color:
                        isUploaded ? Colors.green : AppColors.mutedForeground,
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
                          color: isUploaded
                              ? Colors.green
                              : AppColors.foreground,
                          fontWeight: isUploaded
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (!isUploaded) ...[
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
        return 'Commerce';
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
