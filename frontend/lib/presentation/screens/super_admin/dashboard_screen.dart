import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app/data/datasources/super_admin_api_service.dart';

class DashboardScreen extends StatefulWidget {
  /// Callback appelé quand l'admin clique sur "Voir tous" dans la section
  /// inscriptions en attente — permet de naviguer vers l'onglet Utilisateurs.
  final VoidCallback? onNavigateToUsers;

  const DashboardScreen({super.key, this.onNavigateToUsers});

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
  List<dynamic> _pendingUsers = [];

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

          // Inscriptions en attente
          _pendingUsers = (alerts['pending_validations'] as List<dynamic>?) ?? [];
          print('⏳ Pending users: ${_pendingUsers.length}');

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
          if (_pendingUsers.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildPendingRegistrationsSection(context),
          ],
          const SizedBox(height: 32),
          _buildChartsSection(context),
        ],
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final isTablet = width >= 600;

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.3 : 1.15),
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

  // ─── Section : Inscriptions en attente ───────────────────────────────────────

  Widget _buildPendingRegistrationsSection(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCA28), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCA28).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCA28).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.userCheck,
                    color: Color(0xFFF57F17), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Inscriptions en attente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57F17),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF57F17),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_pendingUsers.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ces comptes nécessitent votre validation avant activation.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF795548)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Liste des utilisateurs en attente
          ...(_pendingUsers.take(isDesktop ? 5 : 3).map((user) {
            final role = user['role']?.toString() ?? '';
            final nom = user['nom']?.toString() ?? 'Sans nom';
            final isLivreur = role == 'livreur';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isLivreur ? Colors.blue : Colors.deepPurple)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isLivreur ? LucideIcons.bike : LucideIcons.store,
                      size: 16,
                      color: isLivreur ? Colors.blue : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nom,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4E342E)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isLivreur ? Colors.blue : Colors.deepPurple)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLivreur ? 'Livreur' : 'Commerce',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLivreur ? Colors.blue : Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })).toList(),
          if (_pendingUsers.length > (isDesktop ? 5 : 3)) ...[
            const SizedBox(height: 4),
            Text(
              '+ ${_pendingUsers.length - (isDesktop ? 5 : 3)} autre(s)…',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF795548)),
            ),
          ],
          const SizedBox(height: 16),
          // Bouton de navigation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: const Text('Voir tous les utilisateurs en attente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57F17),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: widget.onNavigateToUsers,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Graphiques ──────────────────────────────────────────────────────────────

  Widget _buildChartsSection(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildRevenueChart(isDesktop: true)),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildOrdersPieChart(isDesktop: true)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildRevenueChart(isDesktop: false),
          const SizedBox(height: 24),
          _buildOrdersPieChart(isDesktop: false),
        ],
      );
    }
  }

  Widget _buildRevenueChart({required bool isDesktop}) {
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
              height: isDesktop ? 250 : 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1000,
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}€');
                        },
                        reservedSize: 40,
                      ),
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

  Widget _buildOrdersPieChart({required bool isDesktop}) {
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
              height: isDesktop ? 200 : 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _ordersStatus.map((status) {
                    int colorValue;
                    if (status['color'] is String) {
                      String colorHex = status['color'] as String;
                      colorValue =
                          int.parse(colorHex.replaceFirst('#', '0xFF'));
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
                          width: 12,
                          height: 12,
                          color: status['color'] is String
                              ? Color(int.parse((status['color'] as String)
                                  .replaceFirst('#', '0xFF')))
                              : Color(status['color'] as int? ?? 0xFF000000)),
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
