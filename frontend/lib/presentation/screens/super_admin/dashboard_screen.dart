import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app/data/datasources/super_admin_api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = SuperAdminApiService();

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _liveDrivers = [];
  List<dynamic> _chartData = [];
  List<dynamic> _ordersStatus = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      print('🔍 Loading dashboard data...');
      final stats = await _apiService.getKPIs();
      print('📊 KPIs: $stats');
      
      final chartData = await _apiService.getChartData();
      print('📈 Chart Data: $chartData');
      
      final alerts = await _apiService.getAlerts();
      final driversResponse = await _apiService.getLiveDrivers();

      if (mounted) {
        setState(() {
          _stats = stats;
          _chartData = (chartData['weeklyRevenue'] as List<dynamic>?) ?? [];
          _ordersStatus = (chartData['ordersByStatus'] as List<dynamic>?) ?? [];
          
          // Limiter à 7 jours maximum pour éviter les bâtonnets infinis
          if (_chartData.length > 7) {
            _chartData = _chartData.take(7).toList();
          }
          
          print('✅ Chart Data Length: ${_chartData.length}');
          print('✅ Orders Status Length: ${_ordersStatus.length}');
          
          _liveDrivers = driversResponse is List
              ? driversResponse
              : ((driversResponse as Map<String, dynamic>)['data'] as List<dynamic>? ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Dashboard loading ERROR: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aperçu du jour',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildKPIGrid(context),
          const SizedBox(height: 32),
          _buildChartsSection(context),
        ],
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
            'Commandes Actives',
            _stats['commandes_actives']?.toString() ?? '0',
            LucideIcons.package2,
            AppColors.accent),
        _buildKPICard('Revenus du jour', '${_stats['revenus_jour'] ?? 0} MAD',
            LucideIcons.coins, Colors.green),
        _buildKPICard(
            'Livreurs actifs',
            _stats['livreurs_actifs']?.toString() ?? '0',
            LucideIcons.bike,
            Colors.blue),
        _buildKPICard(
            'Nouveaux Utilisateurs',
            _stats['nouveaux_users']?.toString() ?? '0',
            LucideIcons.userPlus,
            Colors.purple),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.cardShadow[0].color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                )
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildRevenueChart()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildOrdersPieChart()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildOrdersPieChart(),
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
            const Text('Évolution des revenus (Semaine)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 250000, // Augmenter pour éviter les bâtonnets infinis
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _chartData.length)
                            return const Text('');
                          return Text(_chartData[value.toInt()]['day'] ?? '');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _chartData
                      .asMap()
                      .entries
                      .map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['revenue'] ?? 0).toDouble(),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersPieChart() {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statuts des commandes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _ordersStatus.map((status) {
                    int colorValue;
                    if (status['color'] is String) {
                      String colorHex = status['color'] as String;
                      colorValue = int.parse(colorHex.replaceFirst('#', '0xFF'));
                    } else {
                      colorValue = status['color'] as int? ?? 0xFF000000;
                    }
                    
                    return PieChartSectionData(
                      color: Color(colorValue),
                      value: (status['count'] ?? 0).toDouble(),
                      title: '${status['count'] ?? 0}',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: _ordersStatus.map((status) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                          width: 12, height: 12, color: Color(status['color'] ?? 0xFF000000)),
                      const SizedBox(width: 8),
                      Text(status['status'] ?? 'Inconnu'),
                    ],
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
