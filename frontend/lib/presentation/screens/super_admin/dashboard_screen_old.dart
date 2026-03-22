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
  List<dynamic> _topLivreurs = [];
  List<dynamic> _topCommerce = [];
  List<dynamic> _ordersStatus = [];
  List<dynamic> _liveDrivers = [];

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
      
      final statsData = await _apiService.getRevenus();
      print('📈 Stats Data: $statsData');
      
      final driversResponse = await _apiService.getLiveDrivers();

      if (mounted) {
        setState(() {
          _stats = stats;
          _ordersStatus = (chartData['ordersByStatus'] as List<dynamic>?) ?? [];
          
          // Récupérer les top livreurs et commerce depuis les stats
          if (statsData['success'] == true) {
            final data = statsData['data'];
            _topLivreurs = (data['livreurStats'] as List<dynamic>?)?.take(5).toList() ?? [];
            _topCommerce = (data['businessStats'] as List<dynamic>?)?.take(7).toList() ?? [];
          }
          
          print('✅ Top Livreurs: ${_topLivreurs.length}');
          print('✅ Top Commerce: ${_topCommerce.length}');
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
            'Tableau de Bord',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildKPIGrid(context),
          const SizedBox(height: 32),
          _buildStatisticsSection(context),
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

  Widget _buildStatisticsSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildOrdersPieChart()),
          const SizedBox(width: 24),
          Expanded(child: _buildTopLivreurs()),
          const SizedBox(width: 24),
          Expanded(child: _buildTopCommerce()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildOrdersPieChart(),
          const SizedBox(height: 24),
          _buildTopLivreurs(),
          const SizedBox(height: 24),
          _buildTopCommerce(),
        ],
      );
    }
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
            const Text('Répartition des commandes',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopLivreurs() {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Livreurs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._topLivreurs.asMap().entries.map((entry) {
              final livreur = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            livreur['nom'] ?? 'Nom',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${livreur['deliveries_count'] ?? 0} livraisons',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${livreur['rating'] ?? 0}⭐',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${livreur['total_revenue'] ?? 0} MAD',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCommerce() {
    return Card(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Commerce',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._topCommerce.asMap().entries.map((entry) {
              final commerce = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commerce['nom'] ?? 'Nom',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            commerce['type'] ?? 'Type',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${commerce['rating'] ?? 0}⭐',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${commerce['revenue'] ?? 0} MAD',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
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
}
