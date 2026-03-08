import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/livreur_mock_datasource.dart';
import '../../../data/models/commande_model.dart';
import '../../../data/models/gains_model.dart';
import '../../../presentation/widgets/livreur/status_toggle_button.dart';
import '../../../presentation/widgets/livreur/gains_stat_card.dart';
import '../../../presentation/widgets/livreur/nouvelle_commande_card.dart';
import '../../../presentation/widgets/livreur/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOnline       = false;
  bool _hasCommande    = false;
  bool _isLoading      = true;
  int  _navIndex       = 0;

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
      // Simuler une nouvelle commande 2s après être En ligne
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
    setState(() => _hasCommande = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande acceptée ! Rendez-vous au restaurant.'),
        backgroundColor: AppColors.navyDark,
      ),
    );
    // TODO: Navigator.push vers LivraisonActiveScreen
  }

  void _onRefuser() {
    setState(() {
      _hasCommande = false;
      _commande    = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header Navy ──────────────────────────────────────
          _buildHeader(),

          // ── Contenu scrollable ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Cards stats
                  if (_gains != null) _buildStatsRow(),
                  const SizedBox(height: 16),

                  // Card nouvelle commande (si En ligne + commande dispo)
                  if (_isOnline && _hasCommande && _commande != null)
                    NouvelleCommandeCard(
                      commande:   _commande!,
                      onAccepter: _onAccepter,
                      onRefuser:  _onRefuser,
                    ),

                  // Message si En ligne mais pas de commande
                  if (_isOnline && !_hasCommande)
                    _buildWaitingMessage(),
                ],
              ),
            ),
          ),

          // ── Bottom Nav ────────────────────────────────────────
          LivreurBottomNavBar(
            currentIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width:   double.infinity,
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 16,
        left:   20,
        right:  20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bonjour + avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.bonjour,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: const [
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
              // Avatar
              CircleAvatar(
                radius:          24,
                backgroundColor: AppColors.navyMedium,
                child: const Icon(Icons.person, color: AppColors.textSecondary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Toggle bouton
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
      margin:  const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(Icons.access_time_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
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