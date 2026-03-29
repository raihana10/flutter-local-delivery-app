import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';


class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.roleId != null) {
        context.read<OrderProvider>().fetchOrderHistory(auth.roleId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Commandes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.forest,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (orderProvider.errorMessage != null) {
            return _buildErrorState(orderProvider.errorMessage!);
          }

          final orders = orderProvider.orderHistory;

          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.warmWhite.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.package, 
                size: 64, color: AppColors.forest.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune commande passée',
            style: TextStyle(
              color: AppColors.forest,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos commandes apparaîtront ici dès que vous\naurez passé votre première commande.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.triangleAlert, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Oups ! Une erreur est survenue',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchHistory,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(order['created_at'].toString()) ?? DateTime.now();
    final items = order['ligne_commande'] as List? ?? [];
    
    // Get first business name from products
    String businessName = "LIVRAPP";
    if (items.isNotEmpty && items[0]['produit'] != null) {
      businessName = items[0]['produit']['business']?['app_user']?['nom'] ?? "Commerce";
    }

    final String dateStr = "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";
    final String timeStr = "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.shoppingBag, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('$dateStr à $timeStr', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                    ],
                  ),
                ),
                _StatusBadge(status: order['statut_commande']),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${items.length} ${items.length > 1 ? 'articles' : 'article'}', 
                          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        items.map((i) => i['nom_snapshot']).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${order['prix_total']} MAD',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _OrderDetailsSheet(order: order),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.sage),
                ),
                child: const Text('Détails de la commande', style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderDetailsSheet({required this.order});

  Future<Uint8List> _generatePdf(Map<String, dynamic> order, List<dynamic> lines) async {
    final pdf = pw.Document();
    final businessName = order['business']?['app_user']?['nom'] ?? 'Établissement';
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('LIVRAPP', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text('REÇU DE COMMANDE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Établissement: $businessName'),
              pw.Text('Commande #${order['id_commande']}'),
              pw.Text('Date: ${order['created_at'].toString().split('T')[0]}'),
              pw.Divider(),
              ...lines.map((l) {
                 final qty = l['quantite'];
                 final price = l['prix_snapshot'];
                 final prodName = l['nom_snapshot'] ?? 'Produit';
                 return pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                     pw.Expanded(child: pw.Text('$qty x $prodName', style: const pw.TextStyle(fontSize: 9))),
                     pw.Text('${(double.parse(price.toString()) * (qty as int)).toStringAsFixed(2)} MAD', style: const pw.TextStyle(fontSize: 9)),
                   ],
                 );
              }).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SOUS-TOTAL', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${((order['prix_total'] as num?)?.toDouble() ?? 0.0) - ((order['frais_livraison'] as num?)?.toDouble() ?? 0.0)} MAD', style: const pw.TextStyle(fontSize: 10)),
                ]
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FRAIS DE LIVRAISON', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${(order['frais_livraison'] as num?)?.toDouble() ?? 0.0} MAD', style: const pw.TextStyle(fontSize: 10)),
                ]
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text('${order['prix_total']} MAD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Merci pour votre confiance !', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
            ]
          );
        }
      )
    );

    return pdf.save();
  }

  void _showReceiptPreview(BuildContext context, Map<String, dynamic> order, List<dynamic> lines) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mon Reçu'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: PdfPreview(
          build: (format) => _generatePdf(order, lines),
          allowSharing: true,
          allowPrinting: true,
          canChangeOrientation: false,
          canChangePageFormat: false,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = order['ligne_commande'] as List<dynamic>? ?? [];
    final businessName = order['business']?['app_user']?['nom'] ?? 'Établissement';
    final createdAt = DateTime.parse(order['created_at']);
    final dateStr = "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Détails de la commande', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Facturé le $dateStr', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  ],
                ),
                _StatusBadge(status: order['statut_commande']),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Business Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.store, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('${item['quantite']}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(item['nom_snapshot'] ?? 'Produit', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      ),
                      Text('${(double.parse(item['prix_snapshot'].toString()) * (item['quantite'] as int)).toStringAsFixed(2)} MAD', 
                           style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )).toList(),
                const Divider(height: 32),
                Builder(
                  builder: (context) {
                    final double total = (order['prix_total'] as num?)?.toDouble() ?? 0.0;
                    final double deliveryFee = (order['frais_livraison'] as num?)?.toDouble() ?? 0.0;
                    final double subTotal = total - deliveryFee;
                    
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sous-total', style: TextStyle(color: AppColors.mutedForeground)),
                            Text('${subTotal.toStringAsFixed(2)} MAD', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Frais de livraison', style: TextStyle(color: AppColors.mutedForeground)),
                            Text('${deliveryFee.toStringAsFixed(2)} MAD', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('${total.toStringAsFixed(2)} MAD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 40),
                // Actions
                OutlinedButton.icon(
                  onPressed: () => _showReceiptPreview(context, order, items),
                  icon: const Icon(LucideIcons.fileText, size: 18),
                  label: const Text('Voir le reçu (PDF)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Retour', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    String label = status ?? 'Inconnu';

    switch (status) {
      case 'confirmee': color = Colors.blue; label = 'Confirmée'; break;
      case 'preparee': color = AppColors.primary; label = 'Préparée'; break;
      case 'en_livraison': color = AppColors.gold; label = 'En livraison'; break;
      case 'livree': color = AppColors.online; label = 'Livrée'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9),
      ),
    );
  }
}
