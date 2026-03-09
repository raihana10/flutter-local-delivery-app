import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/constants/app_strings.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/data/datasources/livreur_mock_datasource.dart';
import 'package:app/data/models/commande_model.dart';
import 'package:app/data/models/gains_model.dart';
import 'package:app/presentation/widgets/livreur/status_toggle_button.dart';
import 'package:app/presentation/widgets/livreur/gains_stat_card.dart';
import 'package:app/presentation/widgets/livreur/nouvelle_commande_card.dart';
import 'package:app/presentation/widgets/livreur/bottom_nav_bar.dart';
import 'package:app/presentation/screens/livreur/livraison_active_screen.dart';
import 'package:app/presentation/screens/livreur/gains_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOnline    = false;
  bool _hasCommande = false;
  bool _isLoading   = true;
  int  _navIndex    = 0;

  CommandeModel? _commande;
  GainsModel?   _gains;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final gains = await LivreurMockDatasource.withDelay(LivreurMockDatasource.mockGains);
    if (mounted) {
      setState(() {
        _gains     = gains;
        _isLoading = false;
      });
    }
  }

  void _toggleStatus() {
    setState(() {
      _isOnline = !_isOnline;
      if (_isOnline) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isOnline) {
            setState(() {
              _commande    = LivreurMockDatasource.mockCommande;
              _hasCommande = true;
            });
          }
        });
      } else {
        _commande    = null;
        _hasCommande = false;
      }
    });
  }

  void _onAccepter() {
    final commande = _commande;
    setState(() => _hasCommande = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivraisonActiveScreen(commande: commande),
      ),
    );
  }

  void _onRefuser() {
    setState(() {
      _hasCommande = false;
      _commande    = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1626) : AppColors.background,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_gains != null) _buildStatsRow(),
                  const SizedBox(height: 16),
                  if (_isOnline && _hasCommande && _commande != null)
                    NouvelleCommandeCard(
                      commande:   _commande!,
                      onAccepter: _onAccepter,
                      onRefuser:  _onRefuser,
                    ),
                  if (_isOnline && !_hasCommande)
                    _buildWaitingMessage(),
                ],
              ),
            ),
          ),
          LivreurBottomNavBar(
            currentIndex: _navIndex,
            onTap: (i) {
              setState(() => _navIndex = i);
              if (i == 1 && _commande != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => LivraisonActiveScreen(commande: _commande),
                ));
              }
              if (i == 2) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const GainsScreen(),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 16,
        left:   20,
        right:  20,
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
                children: const [
                  Text(
                    AppStrings.bonjour,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  Row(
                    children: [
                      Text(
                        'Mohammed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('🛵', style: TextStyle(fontSize: 20)),
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
                        width: 36, height: 36,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.navyMedium,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                          color: AppColors.yellow,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Avatar
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.navyMedium,
                    child: Icon(Icons.person, color: AppColors.textSecondary, size: 28),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatusToggleButton(
            isOnline: _isOnline,
            onToggle: _toggleStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        GainsStatCard(
          label:    AppStrings.aujourdhui,
          montant:  _gains!.aujourdhui,
          dotColor: AppColors.yellow,
        ),
        const SizedBox(width: 12),
        GainsStatCard(
          label:    AppStrings.cetteSemaine,
          montant:  _gains!.semaine,
          dotColor: Colors.blueAccent,
        ),
      ],
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