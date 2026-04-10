import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/super_admin_api_service.dart';

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
    try {
      final res = await _api.getCommissions();
      final livreursRes = await _api.getLivreurs();

      if (mounted) {
        setState(() {
          _totalApp = (res['revenus_app_total'] ?? 0).toDouble();
          _totalLivreurs = (res['revenus_livreurs_total'] ?? 0).toDouble();
          _totalBusinesses = (res['revenus_businesses_total'] ?? 0).toDouble();
          _details = res['detail'] ?? [];
          
          final seen = <int>{};
          _livreurs = livreursRes.where((l) {
            final id = l['id_user'] as int?;
            if (id == null || seen.contains(id)) return false;
            seen.add(id);
            return true;
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paiements & Commissions',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              
              // Cartes de résumé
              if (isMobile)
                _buildMobileSummaryCards()
              else if (isTablet)
                _buildTabletSummaryCards()
              else
                _buildDesktopSummaryCards(),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Section détails
              Text(
                'Détail par commande',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              
              if (isMobile)
                _buildMobilePaymentList()
              else
                _buildDesktopPaymentTable(),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Section livreurs
              Text(
                'Gains par livreur',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildLivreurList(isMobile: isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileSummaryCards() {
    return Column(
      children: [
        _buildSummaryCard(
          'Total revenus app',
          _formatAmount(_totalApp),
          LucideIcons.coins,
          AppColors.accent,
          isMobile: true,
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Total versé livreurs',
          _formatAmount(_totalLivreurs),
          LucideIcons.truck,
          AppColors.secondary,
          isMobile: true,
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Total versé businesses',
          _formatAmount(_totalBusinesses),
          LucideIcons.store,
          AppColors.primary,
          isMobile: true,
        ),
      ],
    );
  }

  Widget _buildTabletSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total revenus app',
                _formatAmount(_totalApp),
                LucideIcons.coins,
                AppColors.accent,
                isMobile: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Total versé livreurs',
                _formatAmount(_totalLivreurs),
                LucideIcons.truck,
                AppColors.secondary,
                isMobile: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          'Total versé businesses',
          _formatAmount(_totalBusinesses),
          LucideIcons.store,
          AppColors.primary,
          isMobile: false,
        ),
      ],
    );
  }

  Widget _buildDesktopSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total revenus app',
            _formatAmount(_totalApp),
            LucideIcons.coins,
            AppColors.accent,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total versé livreurs',
            _formatAmount(_totalLivreurs),
            LucideIcons.truck,
            AppColors.secondary,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total versé businesses',
            _formatAmount(_totalBusinesses),
            LucideIcons.store,
            AppColors.primary,
            isMobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePaymentList() {
    if (_details.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune transaction',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _details.length,
      itemBuilder: (context, index) {
        final comm = _details[index];
        final app = (comm['revenus_app'] ?? 0).toDouble();
        final sLivr = (comm['revenus_livreur'] ?? 0).toDouble();
        final sBus = (comm['revenus_business'] ?? 0).toDouble();
        final pdxTotal = (comm['prix_total'] ?? 0).toDouble();
        final fraisLiv = (comm['frais_livraison'] ?? 0).toDouble();
        final dist = (comm['distance_km'] ?? 0).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec ID et montant total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${comm['id_commande']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      _formatAmount(pdxTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Info ligne 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Distance',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${dist.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Info ligne 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Frais livraison',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatAmount(fraisLiv),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 20),
                
                // Détail des commissions
                _buildCompactPaymentRow('Business (75%)', sBus, color: Colors.blue),
                const SizedBox(height: 4),
                _buildCompactPaymentRow('Livreur (85%)', sLivr, color: Colors.orange),
                const SizedBox(height: 4),
                _buildCompactPaymentRow(
                  'App (25%+15%)',
                  app,
                  color: Colors.green,
                  bold: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactPaymentRow(String label, double value, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
        Text(
          _formatAmount(value),
          style: TextStyle(
            fontSize: 13,
            color: color ?? AppColors.foreground,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopPaymentTable() {
    if (_details.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune transaction',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 900, // Largeur minimale pour le tableau
          child: PaginatedDataTable(
            rowsPerPage: _details.length > 10 ? 10 : (_details.isEmpty ? 1 : _details.length),
            columns: const [
              DataColumn(
                label: Text('#ID', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Distance', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Produits', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Livraison', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Business', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Livreur', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('App', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            source: _PaymentDataTableSource(data: _details),
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowHeight: 56,
          ),
        ),
      ),
    );
  }

  Widget _buildLivreurList({required bool isMobile}) {
    if (_livreurs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Aucun livreur trouvé',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _livreurs.length,
      itemBuilder: (ctx, i) {
        final liv = _livreurs[i];
        return _LivreurListItem(
          livreur: liv,
          api: _api,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M MAD';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k MAD';
    }
    return '${amount.toStringAsFixed(2)} MAD';
  }
}

class _LivreurListItem extends StatefulWidget {
  final dynamic livreur;
  final SuperAdminApiService api;
  final bool isMobile;
  
  const _LivreurListItem({
    required this.livreur,
    required this.api,
    required this.isMobile,
  });

  @override
  State<_LivreurListItem> createState() => _LivreurListItemState();
}

class _LivreurListItemState extends State<_LivreurListItem> {
  double _gains = 0;
  int _nbCourses = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGains();
  }

  Future<void> _loadGains() async {
    try {
      final livreurData = widget.livreur['livreur'];
      final idLivreur = livreurData is List && livreurData.isNotEmpty
          ? livreurData[0]['id_livreur']
          : (livreurData is Map ? livreurData['id_livreur'] : null);

      if (idLivreur == null) {
        if (mounted) {
          setState(() {
            _gains = 0;
            _nbCourses = 0;
            _loading = false;
          });
        }
        return;
      }

      final parsedId = idLivreur is int ? idLivreur : int.tryParse(idLivreur.toString()) ?? 0;
      final res = await widget.api.getLivreurGains(parsedId);
      
      if (mounted) {
        setState(() {
          _gains = (res['total_gains'] ?? 0).toDouble();
          _nbCourses = (res['nb_courses'] ?? 0) as int;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatGains(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 12,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: isMobile ? 40 : 48,
              height: isMobile ? 40 : 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.truck,
                size: isMobile ? 20 : 24,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.livreur['nom'] ?? 'Inconnu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (_loading)
                    SizedBox(
                      height: 12,
                      width: 60,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_nbCourses course${_nbCourses > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Gains
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                ),
                child: Text(
                  '${_formatGains(_gains)} MAD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.green[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDataTableSource extends DataTableSource {
  final List<dynamic> data;
  
  _PaymentDataTableSource({required this.data});

  String _formatCompact(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(2);
  }

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    
    final comm = data[index];
    final app = (comm['revenus_app'] ?? 0).toDouble();
    final sLivr = (comm['revenus_livreur'] ?? 0).toDouble();
    final sBus = (comm['revenus_business'] ?? 0).toDouble();
    final pdxTotal = (comm['prix_total'] ?? 0).toDouble();
    final fraisLiv = (comm['frais_livraison'] ?? 0).toDouble();
    final dist = (comm['distance_km'] ?? 0).toDouble();

    return DataRow(
      cells: [
        DataCell(
          Text(
            '#${comm['id_commande']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text('${dist.toStringAsFixed(1)} km')),
        DataCell(Text('${_formatCompact(pdxTotal)} MAD')),
        DataCell(Text('${_formatCompact(fraisLiv)} MAD')),
        DataCell(
          Text(
            '${_formatCompact(sBus)} MAD',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        DataCell(
          Text(
            '${_formatCompact(sLivr)} MAD',
            style: const TextStyle(color: Colors.orange),
          ),
        ),
        DataCell(
          Text(
            '${_formatCompact(app)} MAD',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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