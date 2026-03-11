import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/data/datasources/mock_super_admin_data.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Calcul simulé de la commission (10% par défaut)
    final double commissionRate = 0.10;

    List<Map<String, dynamic>> commissionsList = MockSuperAdminData.orders.where((o) => o['statut'] == 'livree').map((o) {
      final double total = o['prix_donne'];
      return {
        'id_commande': o['id_commande'],
        'client': o['client'],
        'livreur': o['livreur'] ?? 'Platforme',
        'total': total,
        'commission': total * commissionRate,
        'date': (o['date'] as String).substring(0, 10),
      };
    }).toList();

    double totalCommissions = 0.0;
    for (var c in commissionsList) {
      totalCommissions += c['commission'];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paiements & Commissions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Commissions Totales (Simulées)',
                  '${totalCommissions.toStringAsFixed(2)} MAD',
                  LucideIcons.coins,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Passerelle par défaut',
                  'Simulé (Local)',
                  LucideIcons.creditCard,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          PaginatedDataTable(
            header: const Text('Revenus par Commande (Livrée - 10%)', style: TextStyle(fontWeight: FontWeight.bold)),
            rowsPerPage: commissionsList.length > 5 ? 5 : (commissionsList.isEmpty ? 1 : commissionsList.length),
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Client')),
              DataColumn(label: Text('Livreur')),
              DataColumn(label: Text('Prix Total')),
              DataColumn(label: Text('Commission (10%)')),
              DataColumn(label: Text('Date de prélèvement')),
              DataColumn(label: Text('Moyen de Paiement')),
            ],
            source: _PaymentDataTableSource(data: commissionsList),
          )
        ],
      )
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PaymentDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final String simulatedCard = "**** **** **** 4242";

  _PaymentDataTableSource({required this.data});

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final comm = data[index];

    return DataRow(
      cells: [
        DataCell(Text('#${comm['id_commande']}', style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(comm['client'])),
        DataCell(Text(comm['livreur'])),
        DataCell(Text('${comm['total']} MAD')),
        DataCell(Text('${comm['commission'].toStringAsFixed(2)} MAD', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        DataCell(Text(comm['date'])),
        DataCell(Text(simulatedCard, style: const TextStyle(fontFamily: 'Courier', color: AppColors.mutedForeground))),
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

