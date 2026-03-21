import 'package:flutter/material.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:app/core/providers/livreur_dashboard_provider.dart';
import 'package:app/presentation/widgets/livreur/bottom_nav_bar.dart';
import 'package:app/presentation/screens/livreur/dashboard_screen.dart';
import 'package:app/presentation/screens/livreur/historique_screen.dart';
import 'package:app/presentation/screens/livreur/livraison_active_screen.dart';
import 'package:app/presentation/screens/livreur/livreur_profile_screen.dart';
import 'package:app/data/models/commande_supabase_model.dart';
import 'package:intl/intl.dart';

class LivreurStatsScreen extends StatelessWidget {
  const LivreurStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1626) : AppColors.background,
      appBar: AppBar(
        title: const Text('Statistiques', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<CommandeSupabaseModel>>(
        future: context.read<LivreurDashboardProvider>().fetchHistorique(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final historique = snapshot.data ?? [];
          
          final now = DateTime.now();
          // Filter for last 7 days for the main stats (or this week)
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          
          final thisWeekHistorique = historique.where((c) {
             final d = c.createdAt ?? DateTime.now();
             return d.isAfter(weekStart.subtract(const Duration(days: 1))) && d.isBefore(weekEnd.add(const Duration(days: 1)));
          }).toList();
          
          final totalDistance = thisWeekHistorique.fold(0.0, (sum, c) => sum + (c.distance));
          final totalEarnings = thisWeekHistorique.fold(0.0, (sum, c) => sum + 15.0 + (c.distance * 2.0));
          
          // Chart grouping (Monday = 1, Sunday = 7)
          final Map<int, double> earningsPerDay = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0};
          for (var c in thisWeekHistorique) {
             final day = c.createdAt?.weekday ?? 1;
             earningsPerDay[day] = (earningsPerDay[day] ?? 0.0) + (15.0 + (c.distance * 2.0));
          }
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEarningsHeader(isDark, totalEarnings, weekStart, weekEnd),
                      const SizedBox(height: 24),
                      _buildQuickStats(isDark, thisWeekHistorique.length, totalDistance),
                      const SizedBox(height: 32),
                      _buildChartSection(isDark, earningsPerDay),
                      const SizedBox(height: 32),
                      _buildAchievementsSection(isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
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
      );
     },
    ),
   );
  }

  Widget _buildEarningsHeader(bool isDark, double earnings, DateTime start, DateTime end) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyMedium, AppColors.navyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenus de la semaine',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.trendingUp, color: AppColors.yellow, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${earnings.toStringAsFixed(2)} DH',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Du ${DateFormat('dd MMM', 'fr_FR').format(start)} au ${DateFormat('dd MMM yyyy', 'fr_FR').format(end)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, int count, double distance) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Livraisons',
            value: '$count',
            icon: LucideIcons.package,
            color: Colors.blue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Distance',
            value: '${distance.toStringAsFixed(1)} km',
            icon: LucideIcons.route,
            color: Colors.purple,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Acceptation',
            value: '95 %',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMedium.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isDark, Map<int, double> earningsPerDay) {
    double maxY = 200;
    for (var val in earningsPerDay.values) {
       if (val > maxY) maxY = val + 50;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité de la semaine',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 220,
          padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.navyMedium.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            ),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '\${rod.toY.round()} DH\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.5) : AppColors.mutedForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: [
                _buildBarData(0, earningsPerDay[1] ?? 0, maxY: maxY),
                _buildBarData(1, earningsPerDay[2] ?? 0, maxY: maxY),
                _buildBarData(2, earningsPerDay[3] ?? 0, maxY: maxY),
                _buildBarData(3, earningsPerDay[4] ?? 0, isOffDay: (earningsPerDay[4] == 0), maxY: maxY),
                _buildBarData(4, earningsPerDay[5] ?? 0, maxY: maxY),
                _buildBarData(5, earningsPerDay[6] ?? 0, isHighlighted: true, maxY: maxY),
                _buildBarData(6, earningsPerDay[7] ?? 0, maxY: maxY),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarData(int x, double y, {bool isHighlighted = false, bool isOffDay = false, required double maxY}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 16,
          color: isHighlighted 
              ? AppColors.yellow 
              : (isOffDay ? Colors.grey.withOpacity(0.3) : AppColors.primary),
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Derniers Bonus',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAchievementTile(
          icon: LucideIcons.cloudRain,
          title: 'Bonus Intempéries',
          date: 'Il y a 2 jours',
          amount: '+ 45.00 DH',
          isDark: isDark,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildAchievementTile(
          icon: LucideIcons.target,
          title: 'Objectif: 30 livraisons',
          date: 'Semaine dernière',
          amount: '+ 150.00 DH',
          isDark: isDark,
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildAchievementTile({
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMedium.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.6) : AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
