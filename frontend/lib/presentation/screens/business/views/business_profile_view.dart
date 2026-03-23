import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/business_data_provider.dart';
import '../../client/client_addresses_screen.dart';
import '../business_main_screen.dart';

class BusinessProfileView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;

  const BusinessProfileView({super.key, required this.onNavigate});

  @override
  State<BusinessProfileView> createState() => _BusinessProfileViewState();
}

class _BusinessProfileViewState extends State<BusinessProfileView> {
  bool _isSwitching = false;
  bool _isUploadingPhoto = false;

  Future<void> _pickAndUploadPhoto(BusinessDataProvider provider, String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final ext = picked.path.split('.').last;
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final businessId = provider.profile['id_user']?.toString() ?? 'unknown';
      final storagePath = '$businessId/$fileName';

      await Supabase.instance.client.storage
          .from('alae')
          .uploadBinary(storagePath, bytes, fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'));

      final publicUrl = Supabase.instance.client.storage
          .from('alae')
          .getPublicUrl(storagePath);

      await provider.updateProfile({type == 'logo' ? 'logo_url' : 'cover_url': publicUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${type == 'logo' ? 'Logo' : 'Bannière'} mis à jour avec succès')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessDataProvider>();

    if (provider.isLoading || provider.profile.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forest));
    }

    final profile = provider.profile;
    final appUser = profile['app_user'] ?? {};
    final nom = appUser['nom']?.toString() ?? 'Nom du Restaurant';
    final description = profile['description']?.toString() ?? 'Restaurant';
    final typeBusiness = profile['type']?.toString() ?? 'Restaurant';
    final isOpen = profile['is_open'] == true;
    final horairesRaw = profile['opening_hours'];
    final timePrep = profile['temps_preparation']?.toString() ?? '15';
    final logoUrl = profile['logo_url']?.toString() ?? 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop';
    final coverUrl = profile['cover_url']?.toString() ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&h=300&fit=crop';

    // Build address display string
    final userAddresses = (appUser['user_adresse'] as List<dynamic>? ?? []);
    String addressDisplay = 'Non définie';
    if (userAddresses.isNotEmpty) {
      final primary = userAddresses.firstWhere(
        (ua) => ua['is_default'] == true,
        orElse: () => userAddresses.first,
      );
      final adr = primary['adresse'] ?? {};
      addressDisplay = adr['details']?.toString().isNotEmpty == true
          ? adr['details']
          : adr['ville'] ?? 'Non définie';
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => widget.onNavigate(BusinessScreen.dashboard),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.warmWhite, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.arrowLeft, color: AppColors.forest, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Profil Business', style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),

              // Business Logo & Banner (tappable for upload)
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadPhoto(provider, 'cover'),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.black26,
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.camera, color: Colors.white, size: 24),
                                SizedBox(height: 4),
                                Text('Changer la bannière', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadPhoto(provider, 'logo'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.warmWhite,
                                backgroundImage: NetworkImage(logoUrl),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: AppColors.forest, shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              Center(
                child: Column(
                  children: [
                    Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.forest)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Open Status Toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.sage.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isOpen ? AppColors.sage.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: isOpen ? AppColors.sage : Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(isOpen ? 'Aujourd\'hui: Ouvert' : 'Actuellement Fermé',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isOpen ? AppColors.sage : Colors.red)),
                      ],
                    ),
                    Switch(
                      value: isOpen,
                      onChanged: _isSwitching ? null : (v) async {
                        setState(() => _isSwitching = true);
                        final success = await provider.updateProfile({'is_open': v});
                        setState(() => _isSwitching = false);
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour.')));
                        }
                      },
                      activeColor: AppColors.sage,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text('Informations Générales', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 16)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showEditModal(context, description, timePrep, horairesRaw, provider),
                      child: const Icon(LucideIcons.pencil, color: AppColors.forest, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildActionTile(LucideIcons.store, 'Type de Business', typeBusiness, onTap: () {}),
                    _buildActionTile(LucideIcons.clock, 'Horaires d\'ouverture', _formatHoraires(horairesRaw), onTap: () {}),
                    _buildActionTile(LucideIcons.timer, 'Temps de préparation moyen', '$timePrep mins', onTap: () {}),
                    _buildActionTile(LucideIcons.mapPin, 'Adresse', addressDisplay, onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return AddAddressBottomSheet(
                            onSave: (data) async {
                              return await provider.apiService.addAddress(data);
                            },
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Comptes & Sécurité', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildActionTile(LucideIcons.fileText, 'Documents de validation', 'Validés', isSuccess: true, onTap: () {}),
                    _buildActionTile(LucideIcons.logOut, 'Déconnexion', '', isDestructive: true, onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isSwitching || _isUploadingPhoto)
          Container(
            color: Colors.white54,
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.forest),
                if (_isUploadingPhoto) ...[
                  const SizedBox(height: 12),
                  const Text('Upload en cours...', style: TextStyle(color: AppColors.forest)),
                ]
              ],
            )),
          ),
      ],
    );
  }

  String _formatHoraires(dynamic raw) {
    if (raw == null) return 'Non défini';
    if (raw is List) {
      return (raw as List).join(', ');
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return (decoded as List).join(', ');
      } catch (_) {}
      return raw;
    }
    return 'Voir les horaires';
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle,
      {VoidCallback? onTap, bool isDestructive = false, bool isSuccess = false}) {
    Color color = isDestructive ? Colors.red : AppColors.forest;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDestructive ? Colors.red.withOpacity(0.1) : AppColors.warmWhite, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(color: isSuccess ? AppColors.sage : AppColors.mutedForeground, fontSize: 12, fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.black12, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, String currentDesc, String currentTimePrep, dynamic horairesRaw, BusinessDataProvider provider) {
    final descController = TextEditingController(text: currentDesc);
    final prepController = TextEditingController(text: currentTimePrep);

    // Parse opening hours into a list of slots
    List<String> timeSlots = [];
    if (horairesRaw is List) {
      timeSlots = horairesRaw.map((e) => e.toString()).toList();
    } else if (horairesRaw is String) {
      try {
        final decoded = jsonDecode(horairesRaw);
        if (decoded is List) {
          timeSlots = decoded.map((e) => e.toString()).toList();
        } else {
          timeSlots = [horairesRaw];
        }
      } catch (_) {
        if (horairesRaw.trim().isNotEmpty) timeSlots = [horairesRaw];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modifier les informations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forest)),
                  const SizedBox(height: 24),
                  _buildEditField('Description', descController, maxLines: 3),
                  const SizedBox(height: 16),
                  _buildEditField('Temps de préparation (mins)', prepController, isNumber: true),
                  const SizedBox(height: 24),

                  // Opening hours slots
                  const Text('Horaires d\'ouverture', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Ex: 08:00-12:00 (ajoutez plusieurs créneaux)', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (timeSlots.isEmpty)
                    const Text('Aucun créneau défini', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  ...timeSlots.asMap().entries.map((e) {
                    final i = e.key;
                    final slot = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warmWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.forest.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 16, color: AppColors.forest),
                          const SizedBox(width: 8),
                          Expanded(child: Text(slot, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.forest))),
                          GestureDetector(
                            onTap: () => setModalState(() => timeSlots.removeAt(i)),
                            child: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () async {
                      final startTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                      if (!context.mounted || startTime == null) return;
                      final endTime = await showTimePicker(context: context, initialTime: TimeOfDay(hour: startTime.hour + 4, minute: 0));
                      if (endTime == null) return;
                      final fmt = (TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                      setModalState(() => timeSlots.add('${fmt(startTime)}-${fmt(endTime)}'));
                    },
                    icon: const Icon(LucideIcons.plus, color: AppColors.forest),
                    label: const Text('Ajouter un créneau', style: TextStyle(color: AppColors.forest)),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _isSwitching = true);
                        await provider.updateProfile({
                          'description': descController.text.trim(),
                          'temps_preparation': int.tryParse(prepController.text.trim()) ?? 15,
                          'opening_hours': jsonEncode(timeSlots),
                        });
                        setState(() => _isSwitching = false);
                      },
                      child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
