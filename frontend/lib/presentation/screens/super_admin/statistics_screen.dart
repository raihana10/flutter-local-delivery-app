import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app/data/datasources/super_admin_api_service.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Semaine';
  final _apiService = SuperAdminApiService();

  bool _isLoading = true;
  List<dynamic> _topDrivers = [];
  List<dynamic> _topBusinesses = [];
  List<dynamic> _weeklyRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading statistics...');
      
      // ✅ Appeler les endpoints séparément
      // le endpoint revenus n'est pas très bien utilisé ici, on va s'appuyer sur getChartData pour les revenus globaux aussi
      final livreurStats = await _apiService.getLivreurStats();
      final businessStats = await _apiService.getAllBusinessStats();
      final chartData = await _apiService.getChartData();

      if (mounted) {
        setState(() {
          // Livreurs
          final drivers = List<dynamic>.from(livreurStats['data'] ?? []);
          drivers.sort((a, b) => ((b['nb_courses'] ?? 0) as num)
              .compareTo((a['nb_courses'] ?? 0) as num));
          _topDrivers = drivers.take(3).toList();

          // Businesses
          final businesses = List<dynamic>.from(businessStats['data'] ?? []);
          businesses.sort((a, b) => ((b['revenus_totaux'] ?? 0) as num)
              .compareTo((a['revenus_totaux'] ?? 0) as num));
          _topBusinesses = businesses.take(3).toList();

          // Graphique revenus
          _weeklyRevenue = List<dynamic>.from(chartData['weeklyRevenue'] ?? []);

          _isLoading = false;
        });
      }
    } catch (e) {
      print('STATS ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                          items: [
                            'Aujourd\'hui',
                            'Semaine',
                            'Mois',
                            'Personnalisé'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
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
                      onPressed: () => _exportToCSV(),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            _buildChartsSection(context),
            const SizedBox(height: 32),
            _buildRankings(context),
          ],
        ));
  }

  Widget _buildChartsSection(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            const Text('Revenus Générés (Semaine actuelle)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 150000, // Augmenter pour éviter les bâtonnets infinis
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= _weeklyRevenue.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              _weeklyRevenue[index]['day'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground),
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
                              if (value % 10000 != 0)
                                return const SizedBox.shrink();
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text('${(value / 1000).toInt()}k',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedForeground)),
                              );
                            })),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _weeklyRevenue
                          .asMap()
                          .entries
                          .map((entry) {
                        return FlSpot(entry.key.toDouble(),
                            (entry.value['revenue'] ?? 0).toDouble());
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
            const Text('Répartition par Type de Commerce',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _buildCommerceSections(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCommerceLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildCommerceSections() {
    // Compter les types de commerce
    Map<String, int> typeCounts = {};
    Map<String, double> typeRevenues = {};
    
    for (var commerce in _topBusinesses) {
      String type = commerce['email'] as String? ?? 'Business';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      typeRevenues[type] = (typeRevenues[type] ?? 0) + (commerce['revenus_totaux'] as num? ?? 0).toDouble();
    }
    
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      Colors.orange,
      Colors.purple,
    ];
    
    int index = 0;
    return typeRevenues.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key}',
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).toList();
  }

  Widget _buildCommerceLegend() {
    Map<String, double> typeRevenues = {};
    double totalRevenue = 0;
    
    for (var commerce in _topBusinesses) {
      String type = commerce['email'] as String? ?? 'Business';
      double revenue = (commerce['revenus_totaux'] as num? ?? 0).toDouble();
      typeRevenues[type] = (typeRevenues[type] ?? 0) + revenue;
      totalRevenue += revenue;
    }
    
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      Colors.orange,
      Colors.purple,
    ];
    
    List<Widget> legends = [];
    int index = 0;
    
    for (var entry in typeRevenues.entries) {
      final percentage = totalRevenue > 0 ? (entry.value / totalRevenue * 100).round() : 0;
      final color = colors[index % colors.length];
      index++;
      
      legends.add(LegendIndicator(
        color: color, 
        text: '${entry.key} ($percentage%)'
      ));
      
      if (index < typeRevenues.length) {
        legends.add(const SizedBox(width: 16));
      }
    }
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: legends,
    );
  }

  Widget _buildRankings(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final topDrivers = _topDrivers;
    final topBusinesses = _topBusinesses;

    if (MediaQuery.of(context).size.width >= 800) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Top Livreurs ($_selectedPeriod)',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    for (int i = 0; i < topDrivers.length; i++) ...[
                      if (i > 0) const Divider(),
                      _buildRankingRow(
                          '${i + 1}',
                          topDrivers[i]['nom'] ?? 'Inconnu',
                          '${topDrivers[i]['nb_courses'] ?? 0} courses',
                          '${(topDrivers[i]['note_moyenne'] as num?)?.toStringAsFixed(1) ?? '0'} ★'),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (MediaQuery.of(context).size.width >= 800)
            const SizedBox(width: 24),
          if (MediaQuery.of(context).size.width >= 800)
            Expanded(
              child: Card(
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Top Restaurants / Boutiques ($_selectedPeriod)',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      for (int i = 0; i < topBusinesses.length; i++) ...[
                        if (i > 0) const Divider(),
                        _buildRankingRow(
                            '${i + 1}',
                            topBusinesses[i]['nom'] ?? 'Inconnu',
                            '${(topBusinesses[i]['revenus_totaux'] as num?)?.toStringAsFixed(0) ?? 0} MAD',
                            '${(topBusinesses[i]['note_moyenne'] as num?)?.toStringAsFixed(1) ?? '0'} ★'),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Top Livreurs ($_selectedPeriod)',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < topDrivers.length; i++) ...[
                    if (i > 0) const Divider(),
                    _buildRankingRow(
                        '${i + 1}',
                        topDrivers[i]['nom'] ?? 'Inconnu',
                        '${topDrivers[i]['nb_courses'] ?? 0} courses',
                        '${(topDrivers[i]['note_moyenne'] as num?)?.toStringAsFixed(1) ?? '0'} ★'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Top Restaurants / Boutiques ($_selectedPeriod)',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < topBusinesses.length; i++) ...[
                    if (i > 0) const Divider(),
                    _buildRankingRow(
                        '${i + 1}',
                        topBusinesses[i]['nom'] ?? 'Inconnu',
                        '${(topBusinesses[i]['revenus_totaux'] as num?)?.toStringAsFixed(0) ?? 0} MAD',
                        '${(topBusinesses[i]['note_moyenne'] as num?)?.toStringAsFixed(1) ?? '0'} ★'),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRankingRow(
      String rank, String name, String subtitle, String rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rank == '1'
                ? AppColors.gold
                : AppColors.primary.withOpacity(0.1),
            child: Text(rank,
                style: TextStyle(
                    color: rank == '1' ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mutedForeground)),
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

  void _exportToCSV() async {
    try {
      List<List<dynamic>> csvData = [];
      
      // En-têtes
      csvData.add([
        'Type',
        'Nom', 
        'Revenus (MAD)',
        'Commandes/Livraisons',
        'Taux/Rating',
        'Période'
      ]);
      
      // Ajouter les top livreurs
      for (var driver in _topDrivers) {
        csvData.add([
          'Livreur',
          driver['nom'] ?? 'N/A',
          (driver['total_gains'] ?? 0).toString(),
          (driver['nb_courses'] ?? 0).toString(),
          (driver['note_moyenne'] ?? 0).toString(),
          _selectedPeriod
        ]);
      }
      
      // Ajouter les top commerces
      for (var business in _topBusinesses) {
        csvData.add([
          'Commerce',
          business['nom'] ?? 'N/A',
          (business['revenus_totaux'] ?? 0).toString(),
          (business['nb_commandes'] ?? 0).toString(),
          (business['note_moyenne'] ?? 0).toString(),
          _selectedPeriod
        ]);
      }
      
      // Convertir en CSV
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Créer le blob et télécharger
      final bytes = latin1.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'statistiques_$_selectedPeriod.csv')
        ..click();
      
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Export CSV ($_selectedPeriod) téléchargé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
