import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/business_data_provider.dart';
import '../business_main_screen.dart';

class BusinessProfileView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;

  const BusinessProfileView({super.key, required this.onNavigate});

  @override
  State<BusinessProfileView> createState() => _BusinessProfileViewState();
}

class _BusinessProfileViewState extends State<BusinessProfileView> {

  bool _isSwitching = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessDataProvider>();
    
    if (provider.isLoading || provider.profile.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forest));
    }

    final profile = provider.profile;
    final appUser = profile['app_user'] ?? {};
    final nom = appUser['nom']?.toString() ?? 'Nom du Restaurant';
    // profile['description']
    final description = profile['description']?.toString() ?? 'Restaurant';
    final typeBusiness = profile['type']?.toString() ?? 'Restaurant';
    final isOpen = profile['is_open'] == true;
    final horairesRaw = profile['opening_hours'];
    final horaires = horairesRaw is String ? horairesRaw : (horairesRaw is Map ? 'Voir les horaires' : '08:00 - 23:00');
    final timePrep = profile['temps_preparation']?.toString() ?? '15';
    // Optional banner/logo
    final logoUrl = profile['logo_url']?.toString() ?? 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop';
    final coverUrl = profile['cover_url']?.toString() ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&h=300&fit=crop';

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

              // Business Logo & Banner
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: AppColors.cardShadow,
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.warmWhite,
                          backgroundImage: NetworkImage(logoUrl),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.forest, shape: BoxShape.circle),
                              child: const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Info
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
                        Text(isOpen ? 'Aujourd\'hui: Ouvert' : 'Actuellement Fermé', style: TextStyle(fontWeight: FontWeight.bold, color: isOpen ? AppColors.sage : Colors.red)),
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

              // Menu Settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text('Informations Générales', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 16)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showEditModal(context, description, timePrep, horaires, profile['pdp']?.toString() ?? '', provider),
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
                    _buildActionTile(LucideIcons.clock, 'Horaires d\'ouverture', horaires, onTap: () {}),
                    _buildActionTile(LucideIcons.timer, 'Temps de préparation moyen', '$timePrep mins', onTap: () {}),
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
        if (_isSwitching)
          Container(
            color: Colors.white54,
            child: const Center(child: CircularProgressIndicator(color: AppColors.forest)),
          ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isDestructive = false, bool isSuccess = false}) {
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
                  if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(color: isSuccess ? AppColors.sage : AppColors.mutedForeground, fontSize: 12, fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.black12, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, String currentDesc, String currentTimePrep, String currentHoraires, String currentPdp, BusinessDataProvider provider) {
    final descController = TextEditingController(text: currentDesc);
    final prepController = TextEditingController(text: currentTimePrep);
    final horairesController = TextEditingController(text: currentHoraires == 'Voir les horaires' ? '08:00 - 23:00' : currentHoraires);
    final pdpController = TextEditingController(text: currentPdp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modifier les informations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forest)),
              const SizedBox(height: 24),
              _buildEditField('Description', descController, maxLines: 3),
              const SizedBox(height: 16),
              _buildEditField('Temps de préparation (mins)', prepController, isNumber: true),
              const SizedBox(height: 16),
              _buildEditField('Horaires (ex: 08:00 - 23:00)', horairesController),
              const SizedBox(height: 16),
              _buildEditField('URL Photo de profil', pdpController),
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
                      'opening_hours': horairesController.text.trim(),
                      'pdp': pdpController.text.trim(),
                    });
                    setState(() => _isSwitching = false);
                  },
                  child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
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

