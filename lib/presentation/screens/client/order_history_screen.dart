import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/constants/app_colors.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/auth_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
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
        title: const Text('Historique des commandes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = orderProvider.orderHistory;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.mutedForeground.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune commande trouvée',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final date = DateTime.parse(order['created_at']);
              final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
              
              // Simple summary of items
              final List items = order['ligne_commande'] ?? [];
              final itemsText = items.map((i) => "${i['quantite']}x ${i['nom_snapshot']}").join(', ');

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shopping_bag,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Commande #${order['id_commande']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildStatusBadge(order['statut_commande']),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    Text(
                      itemsText.isNotEmpty ? itemsText : 'Détails non disponibles',
                      style: TextStyle(color: AppColors.foreground, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${order['prix_total']} DH',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary),
                        ),
                        ElevatedButton(
                          onPressed: () {
                             // Logic to reorder
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Recommander',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color = Colors.orange;
    String label = status ?? 'Inconnu';

    switch (status) {
      case 'confirmee': color = Colors.blue; label = 'Confirmée'; break;
      case 'preparee': color = Color(0xFFA555E1); label = 'Préparée'; break;
      case 'en_livraison': color = Colors.orange; label = 'En livraison'; break;
      case 'livree': color = Colors.green; label = 'Livrée'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10),
      ),
    );
  }
}
