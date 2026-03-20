import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../business_main_screen.dart';

class BusinessStatsView extends StatelessWidget {
  final Function(BusinessScreen) onNavigate;

  const BusinessStatsView({super.key, required this.onNavigate});

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
                  onTap: () => onNavigate(BusinessScreen.dashboard),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.warmWhite, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.forest, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Statistiques & Ventes',
                    style: TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ],
            ),
          ),

          // KPIs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildStatCard(
                    'Revenus (Mois)', '45,200', ' MAD', LucideIcons.trendingUp,
                    isUp: true),
                const SizedBox(width: 16),
                _buildStatCard('Commandes', '342', '', LucideIcons.shoppingBag,
                    isUp: true),
              ],
            ),
          ),

          // Chart Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Évolution des revenus',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                          fontSize: 16)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10000,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12);
                                String text;
                                switch (value.toInt()) {
                                  case 0:
                                    text = 'Lun';
                                    break;
                                  case 1:
                                    text = 'Mar';
                                    break;
                                  case 2:
                                    text = 'Mer';
                                    break;
                                  case 3:
                                    text = 'Jeu';
                                    break;
                                  case 4:
                                    text = 'Ven';
                                    break;
                                  case 5:
                                    text = 'Sam';
                                    break;
                                  case 6:
                                    text = 'Dim';
                                    break;
                                  default:
                                    text = '';
                                    break;
                                }
                                return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 4,
                                    child: Text(text, style: style));
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 2500,
                          getDrawingHorizontalLine: (value) => const FlLine(
                              color: AppColors.warmWhite, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeGroupData(0, 5000),
                          _makeGroupData(1, 6500),
                          _makeGroupData(2, 4000),
                          _makeGroupData(3, 8000),
                          _makeGroupData(4, 9500),
                          _makeGroupData(5, 7500),
                          _makeGroupData(6, 6000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Selling Products
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text('Produits les plus vendus',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                    fontSize: 16)),
          ),
          const SizedBox(height: 16),
          _buildTopProductItem(
              '1', 'Tajine au Poulet & Olives', '140 commandes', '12,600 MAD'),
          _buildTopProductItem(
              '2', 'Couscous Royal', '98 commandes', '16,660 MAD'),
          _buildTopProductItem(
              '3', 'Thé à la Menthe', '210 commandes', '3,150 MAD'),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.forest,
          width: 16,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
              show: true, toY: 10000, color: AppColors.warmWhite),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon,
      {bool isUp = true}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.forest, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: AppColors.forest)),
                Text(unit,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    color: isUp ? AppColors.sage : AppColors.destructive,
                    size: 14),
                const SizedBox(width: 4),
                Text(isUp ? '+12% ce mois' : '-5% ce mois',
                    style: TextStyle(
                        color: isUp ? AppColors.sage : AppColors.destructive,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductItem(
      String rank, String name, String orders, String revenue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: rank == '1' ? AppColors.gold : AppColors.warmWhite,
                shape: BoxShape.circle),
            child: Text(rank,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank == '1' ? Colors.white : AppColors.forest)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                        fontSize: 14)),
                Text(orders,
                    style: const TextStyle(
                        color: AppColors.mutedForeground, fontSize: 12)),
              ],
            ),
          ),
          Text(revenue,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
