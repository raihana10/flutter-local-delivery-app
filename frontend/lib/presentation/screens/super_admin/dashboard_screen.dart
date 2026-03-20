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
  Map<String, dynamic> _alerts = {};
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
      final stats = await _apiService.getKPIs();
      final alerts = await _apiService.getAlerts();
      final driversResponse = await _apiService.getLiveDrivers();

      if (mounted) {
        setState(() {
          _stats = stats;
          _alerts = alerts;
          _liveDrivers = driversResponse is List
              ? driversResponse
              : ((driversResponse as Map<String, dynamic>)['data'] as List<dynamic>? ?? []);
          _chartData = (stats['weeklyRevenue'] as List<dynamic>?) ?? [];
          _ordersStatus = (stats['ordersByStatus'] as List<dynamic>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
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
          _buildLiveMap(context),
          const SizedBox(height: 32),
          _buildLiveAlerts(),
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
                  maxY: 30000,
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
                    return PieChartSectionData(
                      color: Color(status['color'] ?? 0xFF000000),
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

  Widget _buildLiveAlerts() {
    final blockedOrders = _alerts['blocked_orders'] as List<dynamic>? ?? [];
    final pendingUsers = _alerts['pending_validations'] as List<dynamic>? ?? [];

    final List<Map<String, dynamic>> dynamicAlerts = [];
    for (var order in blockedOrders) {
      dynamicAlerts.add({
        'titre': 'Commande bloquée',
        'message':
            'La commande #${order['id_commande']} est bloquée depuis ${order['blocked_since']}.',
        'type': 'warning',
        'date': 'A l\'instant',
      });
    }
    for (var user in pendingUsers) {
      dynamicAlerts.add({
        'titre': 'Validation en attente',
        'message':
            'L\'utilisateur #${user['id_user']} attend la validation de ses documents.',
        'type': 'alert',
        'date': 'A l\'instant',
      });
    }

    // dynamicAlerts.addAll(MockSuperAdminData.notifications);

    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.bellRing, color: AppColors.destructive),
                SizedBox(width: 8),
                Text('Alertes système',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.destructive)),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dynamicAlerts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final notif = dynamicAlerts[index];
                final isAlert = notif['type'] == 'alert';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isAlert
                        ? AppColors.destructive.withOpacity(0.1)
                        : AppColors.accent.withOpacity(0.1),
                    child: Icon(
                      isAlert
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: isAlert ? AppColors.destructive : AppColors.accent,
                    ),
                  ),
                  title: Text(notif['titre'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notif['message']),
                  trailing: Text(notif['date'],
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground)),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMap(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Map - Positions des Livreurs',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('En direct',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                image: const DecorationImage(
                  // A beautiful, legal, public placeholder map grid image
                  image: NetworkImage(
                      'https://api.maptiler.com/maps/basic-v2/256/0/0/0.png?key=get_your_own_OpIi9ZULNHzrESv6T2vL'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: _liveDrivers.where((d) => 
                    d['position_order'] != null &&
                    d['position_order']['lat'] != null &&
                    d['position_order']['lng'] != null
                ).map((driver) {
                  final isMission = driver['status'] == 'en_mission';
                  // Simulate coordinates on the center of the viewport
                  final alignX = ((driver['position_order']['lng'] as num) - (-5.36)) * 10;
                  final alignY = ((driver['position_order']['lat'] as num) - 35.58) * -10; // Invert lat for visual accuracy

                  return Align(
                    alignment: Alignment(
                      alignX.clamp(-1.0, 1.0),
                      alignY.clamp(-1.0, 1.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMission ? AppColors.primary : Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: isMission
                                      ? AppColors.primary.withOpacity(0.5)
                                      : Colors.green.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2)
                            ],
                          ),
                          child: Icon(
                              isMission ? LucideIcons.bike : LucideIcons.check,
                              color: Colors.white,
                              size: 16),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4)
                              ]),
                          child: Text(driver['nom'],
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
