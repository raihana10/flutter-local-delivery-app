import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../business_main_screen.dart';
import 'package:provider/provider.dart';
import 'package:app/core/providers/auth_provider.dart';

class BusinessProfileView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;

  const BusinessProfileView({super.key, required this.onNavigate});

  @override
  State<BusinessProfileView> createState() => _BusinessProfileViewState();
}

class _BusinessProfileViewState extends State<BusinessProfileView> {
  bool _isOpen = true;
  final TextEditingController _prepTimeController = TextEditingController(text: '15');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&h=300&fit=crop'),
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
                      backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop'),
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
          const Center(
            child: Column(
              children: [
                Text('Dar Zitoun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.forest)),
                SizedBox(height: 4),
                Text('Restaurant Marocain', style: TextStyle(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Open Status Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _isOpen ? AppColors.sage.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isOpen ? AppColors.sage.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _isOpen ? AppColors.sage : Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text(_isOpen ? 'Aujourd\'hui: Ouvert' : 'Actuellement Fermé', style: TextStyle(fontWeight: FontWeight.bold, color: _isOpen ? AppColors.sage : Colors.red)),
                  ],
                ),
                Switch(
                  value: _isOpen,
                  onChanged: (v) => setState(() => _isOpen = v),
                  activeColor: AppColors.sage,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text('Informations Générales', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildActionTile(LucideIcons.store, 'Type de Business', 'Restaurant', onTap: () {}),
                _buildActionTile(LucideIcons.clock, 'Horaires d\'ouverture', '08:00 - 23:00', onTap: () {}),
                _buildActionTile(LucideIcons.timer, 'Temps de préparation moyen', '15 mins', onTap: () {}),
                _buildActionTile(LucideIcons.mapPin, 'Adresse', '12 Avenue Hassan II, Casablanca', onTap: () {}),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text('Comptes & Sécurité', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildActionTile(LucideIcons.fileText, 'Documents de validation', 'Validés', isSuccess: true, onTap: () {}),
                _buildActionTile(LucideIcons.wallet, 'Détails de paiement', 'Compte bancaire lié', onTap: () {}),
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
}
