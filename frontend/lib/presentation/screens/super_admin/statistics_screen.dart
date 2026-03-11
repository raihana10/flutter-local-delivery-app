import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app/data/datasources/mock_super_admin_data.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Semaine';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 16,
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Statistiques & Rapports',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        items: ['Aujourd\'hui', 'Semaine', 'Mois', 'Personnalisé']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            if (newValue != null) _selectedPeriod = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.download),
                    label: const Text('Exporter CSV'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export CSV simulé ($_selectedPeriod) enregistré en local.')),
                      );
                    },
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildChartsSection(context),
          const SizedBox(height: 32),
          _buildRankings(context),
          const SizedBox(height: 32),
          _buildPromoCodes(),
        ],
      )
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildRevenueChart()),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildOrderTypesPieChart()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildOrderTypesPieChart(),
        ],
      );
    }
  }

  Widget _buildRevenueChart() {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenus Générés (Semaine actuelle)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 30000,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= MockSuperAdminData.weeklyRevenue.length) {
                             return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              MockSuperAdminData.weeklyRevenue[index]['day'],
                              style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % 10000 != 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                             axisSide: meta.axisSide,
                             child: Text('${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                          );
                        }
                      )
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: MockSuperAdminData.weeklyRevenue.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['revenue'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypesPieChart() {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Répartition par Type de Commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: AppColors.primary,
                      value: 65,
                      title: 'Food',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: AppColors.secondary,
                      value: 35,
                      title: 'Shopping',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LegendIndicator(color: AppColors.primary, text: 'Food Delivery (65%)'),
                SizedBox(width: 16),
                LegendIndicator(color: AppColors.secondary, text: 'Shopping (35%)'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRankings(BuildContext context) {
    final drivers = MockSuperAdminData.users.where((u) => u['role'] == 'livreur').toList();
    drivers.sort((a, b) => (b['courses_count'] as int).compareTo(a['courses_count'] as int));
    final topDrivers = drivers.take(3).toList();

    final businesses = MockSuperAdminData.users.where((u) => u['role'] == 'business').toList();
    businesses.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    final topBusinesses = businesses.take(3).toList();

    if (MediaQuery.of(context).size.width >= 800) {
      return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Top Livreurs ($_selectedPeriod)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < topDrivers.length; i++) ...[
                    if (i > 0) const Divider(),
                    _buildRankingRow(
                      '${i + 1}', 
                      topDrivers[i]['nom'], 
                      '${topDrivers[i]['courses_count']} courses', 
                      '${topDrivers[i]['rating']} ★'
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
          if (MediaQuery.of(context).size.width >= 800) const SizedBox(width: 24),
          if (MediaQuery.of(context).size.width >= 800)
            Expanded(
              child: Card(
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Top Restaurants / Boutiques ($_selectedPeriod)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      for (int i = 0; i < topBusinesses.length; i++) ...[
                        if (i > 0) const Divider(),
                        _buildRankingRow(
                          '${i + 1}', 
                          topBusinesses[i]['nom'], 
                          '${topBusinesses[i]['revenue']} MAD', 
                          '${topBusinesses[i]['rating']} ★'
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
       return Column(
        children: [
          Card(
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Top Livreurs ($_selectedPeriod)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < topDrivers.length; i++) ...[
                    if (i > 0) const Divider(),
                    _buildRankingRow(
                      '${i + 1}', 
                      topDrivers[i]['nom'], 
                      '${topDrivers[i]['courses_count']} courses', 
                      '${topDrivers[i]['rating']} ★'
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Top Restaurants / Boutiques ($_selectedPeriod)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < topBusinesses.length; i++) ...[
                    if (i > 0) const Divider(),
                    _buildRankingRow(
                      '${i + 1}', 
                      topBusinesses[i]['nom'], 
                      '${topBusinesses[i]['revenue']} MAD', 
                      '${topBusinesses[i]['rating']} ★'
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRankingRow(String rank, String name, String subtitle, String rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rank == '1' ? AppColors.gold : AppColors.primary.withOpacity(0.1),
            child: Text(rank, style: TextStyle(color: rank == '1' ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(LucideIcons.star, color: AppColors.accent, size: 16),
              const SizedBox(width: 4),
              Text(rating, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPromoCodes() {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Codes Promo Actifs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.05)),
                columns: const [
                  DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Réduction', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Utilisations', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Validité', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: MockSuperAdminData.promoCodes.map((promo) {
                  final isActive = promo['est_actif'] as bool;
                  return DataRow(
                    cells: [
                      DataCell(Text(promo['code'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(promo['reduction'])),
                      DataCell(Text('${promo['utilisation']}')),
                      DataCell(Text((promo['valid_until'] as String).substring(0, 10))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.withOpacity(0.1) : AppColors.destructive.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Actif' : 'Expiré',
                            style: TextStyle(
                              color: isActive ? Colors.green : AppColors.destructive,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendIndicator extends StatelessWidget {
  final Color color;
  final String text;

  const LegendIndicator({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

