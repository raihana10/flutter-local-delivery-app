import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/core/providers/livreur_dashboard_provider.dart';
import 'package:app/presentation/widgets/livreur/bottom_nav_bar.dart';
import 'package:app/presentation/screens/livreur/dashboard_screen.dart';
import 'package:app/presentation/screens/livreur/historique_screen.dart';
import 'package:app/presentation/screens/livreur/livraison_active_screen.dart';
import 'package:app/presentation/screens/livreur/livreur_documents_screen.dart';
import 'package:app/presentation/screens/livreur/livreur_stats_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LivreurProfileScreen extends StatelessWidget {
  const LivreurProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // User Header
                  _buildProfileHeader(context, user),
                  const SizedBox(height: 32),

                  // Profile Sections
                  _buildSection(
                    title: 'Mon activité',
                    items: [
                      _buildListTile(Icons.bar_chart_rounded, 'Statistiques de livraison',
                          onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LivreurStatsScreen()),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Paramètres du compte',
                    items: [
                      _buildListTile(
                          Icons.person_outline, 'Informations personnelles',
                          onTap: () {
                        _showEditProfileDialog(context, user);
                      }),
                      _buildListTile(
                          Icons.pedal_bike_outlined, 'Véhicule et documents',
                          onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LivreurDocumentsScreen()),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Préférences',
                    items: [
                      _buildListTile(Icons.language, 'Langue',
                          trailing: Text('Français',
                              style:
                                  TextStyle(color: AppColors.mutedForeground)),
                          onTap: () {
                        // show dialog
                      }),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _buildListTile(
                            Icons.dark_mode_outlined,
                            'Thème sombre',
                            trailing: Switch(
                              value: themeProvider.isDark,
                              onChanged: (value) => themeProvider.toggleTheme(),
                              activeColor: AppColors.primary,
                            ),
                            onTap: () => themeProvider.toggleTheme(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Autre',
                    items: [
                      _buildListTile(Icons.help_outline, 'Aide et support',
                          onTap: () {}),
                      _buildListTile(Icons.info_outline, 'À propos',
                          onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.destructive.withOpacity(0.1),
                      foregroundColor: AppColors.destructive,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          LivreurBottomNavBar(
            currentIndex: 4,
            onTap: (i) {
              if (i == 4) return;
              final provider = context.read<LivreurDashboardProvider>();
              if (i == 0) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(pageBuilder: (_,__,___) => const DashboardScreen(), transitionDuration: Duration.zero),
                );
              } else if (i == 1 && provider.activeCommande != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LivraisonActiveScreen(commande: provider.activeCommande)),
                );
              } else if (i == 2) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(pageBuilder: (_,__,___) => LivreurStatsScreen(), transitionDuration: Duration.zero),
                );
              } else if (i == 3) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(pageBuilder: (_,__,___) => const HistoriqueScreen(), transitionDuration: Duration.zero),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            try {
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                final authProvider = context.read<AuthProvider>();
                final success = await authProvider.updateProfilePicture(pickedFile);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Photo de profil mise à jour' : 'Erreur lors de la mise à jour de la photo')),
                  );
                }
              }
            } catch (e) {
               debugPrint('Error picking image: $e');
            }
          },
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  image: user?.pdp != null ? DecorationImage(
                    image: NetworkImage(user!.pdp!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: user?.pdp == null ? const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.primary,
                ) : null,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    size: 16, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.nom ?? 'Livreur',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'livreur@example.com',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              int idx = entry.key;
              Widget item = entry.value;
              return Column(
                children: [
                  item,
                  if (idx < items.length - 1)
                    Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title,
      {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios,
              size: 16, color: AppColors.mutedForeground),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    final TextEditingController nameController =
        TextEditingController(text: user.nom);
    final TextEditingController phoneController =
        TextEditingController(text: user.numTl ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(builder: (stContext, setState) {
          return AlertDialog(
            title: const Text('Modifier le profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: 'Nom', hintText: 'Votre nom'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: 'Ex: +212...'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  Text("L'email ne peut pas être modifié.",
                      style: TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Annuler',
                    style: TextStyle(color: AppColors.mutedForeground)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.updateUserProfile(
                          nom: nameController.text.trim(),
                          numTl: phoneController.text.trim(),
                        );

                        if (stContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(stContext).showSnackBar(
                            const SnackBar(
                                content: Text('Profil mis à jour avec succès')),
                          );
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.card, strokeWidth: 2))
                    : const Text('Enregistrer',
                        style: TextStyle(color: AppColors.card)),
              ),
            ],
          );
        });
      },
    );
  }
}
