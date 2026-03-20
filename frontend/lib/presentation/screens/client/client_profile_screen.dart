import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import 'client_notifications_screen.dart';
import 'client_addresses_screen.dart';
import 'client_payment_methods_screen.dart';

import '../../../core/providers/client_data_provider.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final clientData = context.watch<ClientDataProvider>();
    final profile = clientData.profile;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header
            _buildProfileHeader(context, profile, authUser),
            const SizedBox(height: 32),

            // Profile Sections
            _buildSection(
              title: 'Paramètres du compte',
              items: [
                _buildListTile(
                    Icons.person_outline, 'Informations personnelles',
                    onTap: () {
                  _showEditProfileDialog(context, profile, authUser);
                }),
                _buildListTile(
                    Icons.location_on_outlined, 'Adresses de livraison',
                    onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ClientAddressesScreen()));
                }),
                _buildListTile(Icons.payment_outlined, 'Moyens de paiement',
                    onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ClientPaymentMethodsScreen()));
                }),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Préférences',
              items: [
                _buildListTile(Icons.notifications_none, 'Mes notifications',
                    onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClientNotificationsScreen()),
                  );
                }),
                _buildListTile(Icons.notifications_active_outlined,
                    'Paramètres des notifications', onTap: () {
                  _showNotificationSettingsBottomSheet(context);
                }),
                _buildListTile(Icons.language, 'Langue',
                    trailing: Text('Français',
                        style: TextStyle(color: AppColors.mutedForeground)),
                    onTap: () {
                  _showLanguageDialog(context);
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
                _buildListTile(Icons.info_outline, 'À propos', onTap: () {}),
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
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic>? profile, dynamic authUser) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.person,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            GestureDetector(
              onTap: () {
                _showEditPhotoBottomSheet(context);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.camera_alt, size: 16, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile?['nom'] ?? authUser?.nom ?? 'Client Anonyme',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile?['email'] ?? authUser?.email ?? 'client@example.com',
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

  void _showEditPhotoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Ouverture de la galerie...')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Ouverture de l\'appareil photo...')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(
      BuildContext context, Map<String, dynamic>? profile, dynamic authUser) {
    String getName() => profile?['nom'] ?? authUser?.nom ?? '';
    String getEmail() => profile?['email'] ?? authUser?.email ?? '';
    String getPhone() => profile?['num_tl'] ?? '';

    // Extract client relation info if it exists
    Map<String, dynamic>? clientInfo;
    if (profile?['client'] is List && (profile?['client'] as List).isNotEmpty) {
      clientInfo = profile!['client'][0];
    } else if (profile?['client'] is Map) {
      clientInfo = profile!['client'];
    }

    String getBirthDate() => clientInfo?['date_naissance'] ?? '';
    String getSexe() => clientInfo?['sexe'] ?? 'femme';

    final TextEditingController nameController =
        TextEditingController(text: getName());
    final TextEditingController emailController =
        TextEditingController(text: getEmail());
    final TextEditingController phoneController =
        TextEditingController(text: getPhone());
    final TextEditingController birthDateController =
        TextEditingController(text: getBirthDate());
    String selectedGender = getSexe();
    if (selectedGender != 'homme' && selectedGender != 'femme')
      selectedGender = 'femme';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
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
                    controller: emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Email', hintText: 'Votre email'),
                    keyboardType: TextInputType.emailAddress,
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
                  TextField(
                    controller: birthDateController,
                    decoration: const InputDecoration(
                        labelText: 'Date de naissance', hintText: 'JJ/MM/AAAA'),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: 'Sexe'),
                    items: const [
                      DropdownMenuItem(value: 'homme', child: Text('Homme')),
                      DropdownMenuItem(value: 'femme', child: Text('Femme')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val != null) selectedGender = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                    style: TextStyle(color: AppColors.mutedForeground)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: () async {
                  final data = {
                    'nom': nameController.text.trim(),
                    'num_tl': phoneController.text.trim(),
                    'sexe': selectedGender,
                    'date_naissance': birthDateController.text.trim(),
                  };

                  final success = await context
                      .read<ClientDataProvider>()
                      .updateProfile(data);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(success
                              ? 'Profil mis à jour avec succès'
                              : 'Erreur lors de la mise à jour')),
                    );
                  }
                },
                child: const Text('Enregistrer',
                    style: TextStyle(color: AppColors.card)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir la langue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Français'),
                trailing: const Icon(Icons.check, color: AppColors.primary),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('Arabe'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Langue changée en Arabe')));
                },
              ),
              ListTile(
                title: const Text('Anglais'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Langue changée en Anglais')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSettingsBottomSheet(BuildContext context) {
    bool pushEnabled = true;
    bool emailEnabled = false;
    bool promoEnabled = true;
    bool deliveryUpdatesEnabled = true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Paramètres des notifications',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Notifications Push',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Autoriser les alertes sur votre téléphone',
                          style: TextStyle(color: AppColors.mutedForeground)),
                      activeColor: AppColors.primary,
                      value: pushEnabled,
                      onChanged: (val) => setState(() => pushEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text('Mises à jour de livraison',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Suivi de commande, statut livreur',
                          style: TextStyle(color: AppColors.mutedForeground)),
                      activeColor: AppColors.primary,
                      value: deliveryUpdatesEnabled,
                      onChanged: pushEnabled
                          ? (val) =>
                              setState(() => deliveryUpdatesEnabled = val)
                          : null,
                    ),
                    SwitchListTile(
                      title: const Text('Promotions & Offres',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Nouveaux restaurants, réductions',
                          style: TextStyle(color: AppColors.mutedForeground)),
                      activeColor: AppColors.primary,
                      value: promoEnabled,
                      onChanged: pushEnabled
                          ? (val) => setState(() => promoEnabled = val)
                          : null,
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: const Text('Notifications par Email',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Recevoir les reçus par email',
                          style: TextStyle(color: AppColors.mutedForeground)),
                      activeColor: AppColors.primary,
                      value: emailEnabled,
                      onChanged: (val) => setState(() => emailEnabled = val),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Paramètres de notifications enregistrés')),
                        );
                      },
                      child: const Text('Enregistrer',
                          style: TextStyle(
                              color: AppColors.card,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
