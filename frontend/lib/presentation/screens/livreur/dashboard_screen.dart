import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/constants/app_strings.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/livreur_dashboard_provider.dart';
import 'package:app/presentation/widgets/livreur/status_toggle_button.dart';
import 'package:app/presentation/widgets/livreur/nouvelle_commande_card.dart';
import 'package:app/presentation/widgets/livreur/bottom_nav_bar.dart';
import 'package:app/presentation/screens/livreur/livraison_active_screen.dart';
import 'package:app/presentation/screens/livreur/historique_screen.dart';
import 'package:app/presentation/screens/livreur/livreur_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _onAccepter(BuildContext context, dynamic commande) async {
    final provider = context.read<LivreurDashboardProvider>();
    final success = await provider.accepterCommande(commande);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LivraisonActiveScreen(commande: commande),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(provider.errorMessage ?? 'Erreur lors de l\'acceptation')),
      );
    }
  }

  void _onRefuser() {
    // A refuser implies ignoring it or removing it from the local list.
    // For now, doing nothing lets it timeout or someone else take it.
    // We could also add a 'ignoredCommandes' list in provider but let's keep it simple.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardProvider = context.watch<LivreurDashboardProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1626) : AppColors.background,
      body: Column(
        children: [
          _buildHeader(isDark, dashboardProvider),
          Expanded(
            child: dashboardProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        if (dashboardProvider.isOnline &&
                            dashboardProvider.availableCommandes.isNotEmpty)
                          NouvelleCommandeCard(
                            commande:
                                dashboardProvider.availableCommandes.first,
                            onAccepter: () => _onAccepter(context,
                                dashboardProvider.availableCommandes.first),
                            onRefuser: _onRefuser,
                          ),
                        if (dashboardProvider.isOnline &&
                            dashboardProvider.availableCommandes.isEmpty)
                          _buildWaitingMessage(),
                      ],
                    ),
                  ),
          ),
          LivreurBottomNavBar(
            currentIndex: _navIndex,
            onTap: (i) {
              setState(() => _navIndex = i);
              if (i == 1 && dashboardProvider.activeCommande != null) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LivraisonActiveScreen(
                          commande: dashboardProvider.activeCommande),
                    ));
              }
              if (i == 2) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoriqueScreen(),
                    ));
              }
              if (i == 3) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LivreurProfileScreen(),
                    ));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, LivreurDashboardProvider dashboardProvider) {
    final authProvider = context.watch<AuthProvider>();
    final nom = authProvider.user?.nom ?? 'Livreur';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      color: AppColors.navyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bonjour + nom
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.bonjour,
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  Row(
                    children: [
                      Text(
                        nom,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('🛵', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ],
              ),

              // Boutons droite : toggle theme + avatar
              Row(
                children: [
                  // Toggle dark/light
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => GestureDetector(
                      onTap: () => themeProvider.toggleTheme(),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.navyMedium,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          themeProvider.isDark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: AppColors.yellow,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Avatar + Logout
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LivreurProfileScreen()),
                        );
                      } else if (value == 'logout') {
                        await context.read<AuthProvider>().logout();
                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/');
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person,
                                color: AppColors.navyDark, size: 20),
                            SizedBox(width: 8),
                            Text('Mon Profil'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Déconnexion'),
                          ],
                        ),
                      ),
                    ],
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.navyMedium,
                      child: Icon(Icons.person,
                          color: AppColors.textSecondary, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatusToggleButton(
            isOnline: dashboardProvider.isOnline,
            onToggle: () => dashboardProvider.toggleOnlineStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'En attente de commandes...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
