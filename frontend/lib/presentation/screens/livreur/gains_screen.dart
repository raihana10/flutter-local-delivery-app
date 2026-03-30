import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/livreur_dashboard_provider.dart';
import '../../../data/models/gains_model.dart';
import '../../widgets/livreur/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'historique_screen.dart';
import 'livreur_profile_screen.dart';
import 'livraison_active_screen.dart';

class GainsScreen extends StatefulWidget {
  const GainsScreen({super.key});

  @override
  State<GainsScreen> createState() => _GainsScreenState();
}

class _GainsScreenState extends State<GainsScreen> {
  bool _isLoading = true;
  GainsModel? _gains;
  int? _touchedIndex;

  final List<String> _jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final gains = await context.read<LivreurDashboardProvider>().fetchGains();
    if (mounted)
      setState(() {
        _gains = gains ?? GainsModel(
          aujourdhui: 0,
          semaine: 0,
          parJour: List.filled(7, 0.0),
          repartitionType: {'food_delivery': 0, 'shopping': 0},
          livraisonsRecentes: []
        );
        _isLoading = false;
      });
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Bar Chart
                        _buildChartCard(),
                        const SizedBox(height: 24),

                        // Pie Chart
                        if (_gains!.repartitionType.values.any((v) => v > 0)) ...[
                          _buildPieChartCard(),
                          const SizedBox(height: 24),
                        ],

                        // Titre livraisons récentes
                        const Text(
                          AppStrings.livraisonsRecentes,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Liste
                        ..._gains!.livraisonsRecentes
                            .map((l) => _LivraisonTile(livraison: l))
                            .toList(),
                      ],
                    ),
                  ),
          ),

          // ── Bottom Nav ──────────────────────────────────────
          LivreurBottomNavBar(
            currentIndex: 2,
            onTap: (i) {
              if (i == 2) return;
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
              } else if (i == 3) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(pageBuilder: (_,__,___) => const HistoriqueScreen(), transitionDuration: Duration.zero),
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

  // ──────────────────────────────────────────────────────────
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
        AppStrings.mesGains,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.navyDark,
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final maxY = _gains!.parJour.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Totaux semaine
          Row(
            children: [
              _StatBadge(
                  label: "Cette semaine",
                  value: "${_gains!.semaine.toStringAsFixed(0)} MAD"),
              const SizedBox(width: 12),
              _StatBadge(
                  label: "Aujourd'hui",
                  value: "${_gains!.aujourdhui.toStringAsFixed(0)} MAD",
                  isSecondary: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBadge(
                  label: "Total Livraisons",
                  value: "${_gains!.totalLivraisons}",
                  isSecondary: true),
              const SizedBox(width: 12),
              _StatBadge(
                  label: "Distance parcourue",
                  value: "${_gains!.totalDistance.toStringAsFixed(1)} km",
                  isSecondary: true),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY + 60,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot != null) {
                        _touchedIndex = response!.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedIndex = null;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.navyDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)} MAD',
                        const TextStyle(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _jours.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _jours[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: _touchedIndex == i
                                  ? AppColors.yellow
                                  : AppColors.textSecondary,
                              fontWeight: _touchedIndex == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_gains!.parJour.length, (i) {
                  final isTouched = _touchedIndex == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _gains!.parJour[i],
                        color:
                            isTouched ? AppColors.yellow : AppColors.navyDark,
                        width: 22,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    final food = _gains!.repartitionType['food_delivery'] ?? 0;
    final shopping = _gains!.repartitionType['shopping'] ?? 0;
    final total = food + shopping;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Répartition par type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyDark)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        if (food > 0)
                          PieChartSectionData(
                            color: AppColors.yellow,
                            value: food.toDouble(),
                            title: '${((food / total) * 100).toStringAsFixed(0)}%',
                            radius: 30,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyDark),
                          ),
                        if (shopping > 0)
                          PieChartSectionData(
                            color: AppColors.navyDark,
                            value: shopping.toDouble(),
                            title: '${((shopping / total) * 100).toStringAsFixed(0)}%',
                            radius: 30,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieIndicator(color: AppColors.yellow, text: 'Food Delivery ($food)'),
                    const SizedBox(height: 8),
                    _PieIndicator(color: AppColors.navyDark, text: 'Shopping ($shopping)'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieIndicator extends StatelessWidget {
  final Color color;
  final String text;
  const _PieIndicator({required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Widgets locaux ──────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecondary;

  const _StatBadge(
      {required this.label, required this.value, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isSecondary ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: isSecondary ? AppColors.textSecondary : AppColors.navyDark,
          ),
        ),
      ],
    );
  }
}

class _LivraisonTile extends StatelessWidget {
  final LivraisonRecente livraison;

  const _LivraisonTile({required this.livraison});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                livraison.restaurant,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                livraison.heure,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          Text(
            '${livraison.montant.toStringAsFixed(0)} MAD',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
