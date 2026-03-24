import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/data/datasources/super_admin_api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _api = SuperAdminApiService();
  bool _isLoading = true;
  double _totalApp = 0.0;
  double _totalLivreurs = 0.0;
  double _totalBusinesses = 0.0;
  List<dynamic> _details = [];
  List<dynamic> _livreurs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await _api.getCommissions();
    final liv = await _api.getLivreurs();

    if (mounted) {
      setState(() {
        _totalApp = (res['revenus_app_total'] ?? 0).toDouble();
        _totalLivreurs = (res['revenus_livreurs_total'] ?? 0).toDouble();
        _totalBusinesses = (res['revenus_businesses_total'] ?? 0).toDouble();
        _details = res['detail'] ?? [];
        _livreurs = liv;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paiements & Commissions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildSummaryCard('Total revenus app',
                        '$_totalApp MAD', LucideIcons.coins, AppColors.accent)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSummaryCard(
                        'Total versé livreurs',
                        '$_totalLivreurs MAD',
                        LucideIcons.truck,
                        AppColors.secondary)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSummaryCard(
                        'Total versé businesses',
                        '$_totalBusinesses MAD',
                        LucideIcons.store,
                        AppColors.primary)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Détail par commande',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PaginatedDataTable(
                rowsPerPage: _details.length > 5
                    ? 5
                    : (_details.isEmpty ? 1 : _details.length),
                columns: const [
                  DataColumn(
                      label: Text('#ID',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Distance (km)',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Prix produits',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Frais livraison',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Business(×75%)',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Livreur(×70%)',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('App(25%+30%)',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                source: _PaymentDataTableSource(data: _details),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Gains par livreur',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLivreurList(),
          ],
        ));
  }

  Widget _buildLivreurList() {
    if (_livreurs.isEmpty) return const Text('Aucun livreur trouvé.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _livreurs.length,
      itemBuilder: (ctx, i) {
        final liv = _livreurs[i];
        return _LivreurListItem(livreur: liv, api: _api);
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.mutedForeground))),
              ],
            ),
            const SizedBox(height: 16),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _LivreurListItem extends StatefulWidget {
  final dynamic livreur;
  final SuperAdminApiService api;
  const _LivreurListItem({required this.livreur, required this.api});

  @override
  State<_LivreurListItem> createState() => _LivreurListItemState();
}

class _LivreurListItemState extends State<_LivreurListItem> {
  double _gains = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGains();
  }

  Future<void> _loadGains() async {
    final res = await widget.api.getLivreurGains(widget.livreur['id_user']);
    if (mounted) {
      setState(() {
        _gains = (res['recompenses_totales'] ?? 0).toDouble();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(LucideIcons.truck)),
        title: Text(widget.livreur['nom'] ?? 'Inconnu'),
        subtitle: const Text('... courses'),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text('$_gains MAD',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green)),
      ),
    );
  }
}

class _PaymentDataTableSource extends DataTableSource {
  final List<dynamic> data;
  _PaymentDataTableSource({required this.data});

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final comm = data[index];
    final app = (comm['revenus_app'] ?? 0).toDouble().toStringAsFixed(2);
    final sLivr = (comm['revenus_livreur'] ?? 0).toDouble().toStringAsFixed(2);
    final sBus = (comm['revenus_business'] ?? 0).toDouble().toStringAsFixed(2);
    final pdxTotal = (comm['prix_total'] ?? 0).toDouble().toStringAsFixed(2);
    final fraisLiv =
        (comm['frais_livraison'] ?? 0).toDouble().toStringAsFixed(2);
    final dist = (comm['distance_km'] ?? 0).toDouble().toStringAsFixed(2);

    return DataRow(
      cells: [
        DataCell(Text('#${comm['id_commande']}',
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text('$dist km')),
        DataCell(Text('$pdxTotal MAD')),
        DataCell(Text('$fraisLiv MAD')),
        DataCell(Text('$sBus MAD', style: const TextStyle(color: Colors.blue))),
        DataCell(
            Text('$sLivr MAD', style: const TextStyle(color: Colors.orange))),
        DataCell(Text('$app MAD',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}
