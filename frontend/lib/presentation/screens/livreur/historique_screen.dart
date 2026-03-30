import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/livreur_dashboard_provider.dart';
import '../../../data/models/commande_supabase_model.dart';
import '../../widgets/livreur/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'livreur_profile_screen.dart';
import 'livraison_active_screen.dart';
import 'gains_screen.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  bool _isLoading = true;
  List<CommandeSupabaseModel> _historique = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<LivreurDashboardProvider>();
    final data = await provider.fetchHistorique();
    if (mounted) {
      setState(() {
        _historique = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────
          _buildHeader(),

          // ── Contenu ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow))
                : _historique.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun historique de livraison",
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _historique.length,
                          itemBuilder: (context, index) {
                            final commande = _historique[index];
                            return _HistoriqueTile(commande: commande);
                          },
                        ),
                      ),
          ),

          // ── Bottom Nav ──────────────────────────────────────
          LivreurBottomNavBar(
            currentIndex: 3,
            onTap: (i) {
              if (i == 3) return;
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
                  PageRouteBuilder(pageBuilder: (_,__,___) => const GainsScreen(), transitionDuration: Duration.zero),
                );
              } else if (i == 4) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(pageBuilder: (_,__,___) => const LivreurProfileScreen(), transitionDuration: Duration.zero),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      color: Colors.white,
      child: const Text(
        "Mon Historique",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.navyDark,
        ),
      ),
    );
  }
}

// ── Widgets locaux ──────────────────────────────────────────────

class _HistoriqueTile extends StatelessWidget {
  final CommandeSupabaseModel commande;

  const _HistoriqueTile({required this.commande});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Commande #${commande.idCommande}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.navyDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Livrée",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person,
                          size: 14, color: AppColors.navyMedium),
                      const SizedBox(width: 4),
                      Text(
                        commande.clientName ?? 'Client inconnu',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        commande.adresse.length > 25
                            ? '${commande.adresse.substring(0, 25)}...'
                            : commande.adresse,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (commande.items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${commande.items.length} article(s)',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  ]
                ],
              ),
              Text(
                '+ ${(commande.fraisLivraison ?? 0).toStringAsFixed(2)} MAD',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
