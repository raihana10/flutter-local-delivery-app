import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/data/datasources/super_admin_api_service.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  final _apiService = SuperAdminApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getCommandes();
      if (mounted) {
        setState(() {
          orders = data.map((e) {
            final map = Map<String, dynamic>.from(e);
            
            // ✅ Utiliser les champs aplatis retournés par le backend
            map['statut'] = map['statut_commande'] ?? 'confirmee';
            map['type'] = map['type_commande'] ?? 'food_delivery';
            map['date'] = map['created_at'] ?? DateTime.now().toIso8601String();
            
            // ✅ Utiliser les champs retournés par le backend avec les joins
            map['client'] = map['client_nom'] ?? 'Client #${map['id_client']}';
            map['business'] = map['business_nom'] ?? 'Non défini';
            map['livreur'] = map['livreur_nom']; // null si pas assigné
            
            return map;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmee':
        return AppColors.accent;
      case 'preparee':
        return const Color(0xFFF57C00);
      case 'en_livraison':
        return const Color(0xFF1976D2);
      case 'livree':
        return Colors.green;
      default:
        return AppColors.mutedForeground;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'confirmee':
        return 'Confirmée';
      case 'preparee':
        return 'Préparée';
      case 'en_livraison':
        return 'En Livraison';
      case 'livree':
        return 'Livrée';
      default:
        return status;
    }
  }

  void _showRefundDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.banknote, color: AppColors.destructive),
            const SizedBox(width: 8),
            Text('Rembourser #${order['id_commande']}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Voulez-vous vraiment rembourser le client ${order['client']} ?',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Montant à rembourser:',
                      style: TextStyle(color: AppColors.mutedForeground)),
                  Text('${order['prix_donne']} MAD',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
                'Cette action est irréversible et passera le montant payé à 0 MAD.',
                style:
                    TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = orders.indexWhere(
                    (o) => o['id_commande'] == order['id_commande']);
                if (index != -1) {
                  orders[index] = Map<String, dynamic>.from(orders[index]);
                  orders[index]['prix_donne'] = 0.0;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Commande #${order['id_commande']} remboursée avec succès.'),
                        backgroundColor: Colors.green),
                  );
                }
              });
            },
            child: const Text('Confirmer le remboursement'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Commande #${order['id_commande']}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailItem(
                            icon: LucideIcons.user,
                            label: 'Client',
                            value: order['client']),
                        const SizedBox(height: 12),
                        _DetailItem(
                            icon: LucideIcons.store,
                            label: 'Restaurant/Boutique',
                            value: order['business']),
                        const SizedBox(height: 12),
                        _DetailItem(
                            icon: LucideIcons.bike,
                            label: 'Livreur',
                            value: order['livreur'] ??
                                'En attente d\'assignation'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailItem(
                            icon: LucideIcons.calendar,
                            label: 'Date',
                            value: (order['date'] as String)
                                .replaceFirst('T', ' ')
                                .substring(0, 16)),
                        const SizedBox(height: 12),
                        _DetailItem(
                            icon: LucideIcons.tag,
                            label: 'Type',
                            value: order['type']),
                        const SizedBox(height: 12),
                        _DetailItem(
                            icon: LucideIcons.creditCard,
                            label: 'Total Payé',
                            value: '${order['prix_donne']} MAD'),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              const Text('Statut Actuel',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['statut']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(order['statut'])),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.package2,
                        color: _getStatusColor(order['statut'])),
                    const SizedBox(width: 8),
                    Text(
                      _formatStatus(order['statut']).toUpperCase(),
                      style: TextStyle(
                          color: _getStatusColor(order['statut']),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background),
                  child: const Text('Fermer'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion des Commandes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PaginatedDataTable(
                    header: const Text('Toutes les commandes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    rowsPerPage: orders.length > 5
                        ? 5
                        : (orders.isEmpty ? 1 : orders.length),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Client')),
                      DataColumn(label: Text('Restaurant/Boutique')),
                      DataColumn(label: Text('Livreur')),
                      DataColumn(label: Text('Montant payé')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Actions')),
                    ],
                    source: _OrderDataTableSource(
                      data: orders,
                      onViewDetails: _showOrderDetails,
                      onRefund: _showRefundDialog,
                      getStatusColor: _getStatusColor,
                      formatStatus: _formatStatus,
                    ),
                  )
          ],
        ));
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        )
      ],
    );
  }
}

class _OrderDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final void Function(Map<String, dynamic>) onViewDetails;
  final void Function(Map<String, dynamic>) onRefund;
  final Color Function(String) getStatusColor;
  final String Function(String) formatStatus;

  _OrderDataTableSource({
    required this.data,
    required this.onViewDetails,
    required this.onRefund,
    required this.getStatusColor,
    required this.formatStatus,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final order = data[index];
    final statusColor = getStatusColor(order['statut']);

    return DataRow(
      cells: [
        DataCell(Text('#${order['id_commande']}',
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(order['client'])),
        DataCell(Text(order['business'])),
        DataCell(Text(order['livreur'] ?? 'Non assigné',
            style: TextStyle(
                color: order['livreur'] == null
                    ? AppColors.mutedForeground
                    : AppColors.foreground,
                fontStyle: order['livreur'] == null
                    ? FontStyle.italic
                    : FontStyle.normal))),
        DataCell(Text('${order['prix_donne']} MAD',
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  formatStatus(order['statut']),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.eye,
                    color: AppColors.secondary, size: 20),
                tooltip: 'Voir détails',
                onPressed: () => onViewDetails(order),
              ),
              if (order['prix_donne'] > 0)
                IconButton(
                  icon: const Icon(LucideIcons.banknote,
                      color: AppColors.destructive, size: 20),
                  tooltip: 'Rembourser',
                  onPressed: () => onRefund(order),
                ),
            ],
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
