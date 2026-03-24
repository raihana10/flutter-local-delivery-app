import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/client_data_provider.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // ─── Product Detail Dialog ───────────────────────────────────────────────────

  void _showProductDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        int tempQty = item['quantity'] as int;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row: image + name + close
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              item['image'] as String,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.foreground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['price']} DH / unité',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close,
                              color: AppColors.mutedForeground),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),

                    // Quantity section
                    const Text(
                      'Quantité',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (tempQty > 1) {
                                    setModalState(() => tempQty--);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(Icons.remove,
                                      size: 18, color: AppColors.primary),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '$tempQty',
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setModalState(() => tempQty++),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(Icons.add,
                                      size: 18, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Total: ${((item['price'] as double) * tempQty).toStringAsFixed(1)} DH',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            item['quantity'] = tempQty;
                          });
                          // force update to notify listeners
                          final idx = context
                              .read<ClientDataProvider>()
                              .cartItems
                              .indexOf(item);
                          if (idx != -1) {
                            context
                                .read<ClientDataProvider>()
                                .updateCartItem(idx, item);
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Confirmer les modifications',
                          style: TextStyle(
                              color: AppColors.card,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context
                              .read<ClientDataProvider>()
                              .removeFromCart(item);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.destructive, size: 18),
                        label: const Text("Supprimer l'article",
                            style: TextStyle(color: AppColors.destructive)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.destructive),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double? _calcDistance(List<dynamic> addresses, int idx, ClientDataProvider clientData) {
    if (idx < 0 || idx >= addresses.length) return null;
    final adresse = addresses[idx]['adresse'] ?? {};
    final clientLat = double.tryParse(adresse['latitude']?.toString() ?? '');
    final clientLng = double.tryParse(adresse['longitude']?.toString() ?? '');
    
    final cartItems = clientData.cartItems;
    if (cartItems.isEmpty) return null;

    final businessIds = <String>{};
    for (var item in cartItems) {
      final bizId = item['business_id'];
      if (bizId != null) {
        businessIds.add(bizId.toString());
      }
    }

    if (businessIds.length <= 1) {
      final businessAddr = clientData.businessAddress;
      final bizLat = double.tryParse(businessAddr?['latitude']?.toString() ?? '');
      final bizLng = double.tryParse(businessAddr?['longitude']?.toString() ?? '');
      if (clientLat != null && clientLng != null && bizLat != null && bizLng != null) {
        final meters = Geolocator.distanceBetween(bizLat, bizLng, clientLat, clientLng);
        return meters / 1000; // km
      }
    } else {
      final businessAddr = clientData.businessAddress;
      final bizLat = double.tryParse(businessAddr?['latitude']?.toString() ?? '');
      final bizLng = double.tryParse(businessAddr?['longitude']?.toString() ?? '');
      if (clientLat != null && clientLng != null && bizLat != null && bizLng != null) {
        final meters = Geolocator.distanceBetween(bizLat, bizLng, clientLat, clientLng);
        return meters / 1000; // km
      }
    }
    
    return null;
  }

  double _calculateDeliveryFee(double? distanceKm) {
    if (distanceKm == null || distanceKm <= 0) {
      return 1.5;
    }
    double baseFee = distanceKm * 1.5;
    double integerPart = baseFee.truncateToDouble();
    double fraction = baseFee - integerPart;
    
    if (fraction == 0) return baseFee;
    if (fraction <= 0.5) return integerPart + 0.5;
    return integerPart + 1.0;
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final clientData = context.watch<ClientDataProvider>();
    final cartItems = clientData.cartItems;
    final addresses = clientData.addresses;

    int defaultAddrIdx = addresses.indexWhere((a) => a['is_default'] == true);
    if (defaultAddrIdx == -1 && addresses.isNotEmpty) defaultAddrIdx = 0;

    double subtotal = clientData.cartSubtotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Panier',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ...cartItems.map((item) => _buildCartItem(item)),
                      const SizedBox(height: 24),
                      const SizedBox(height: 24),
                      _buildOrderSummary(subtotal),
                    ],
                  ),
                ),
                _buildCheckoutBar(subtotal),
              ],
            ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: AppColors.mutedForeground.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            'Votre panier est vide',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des articles depuis le menu',
            style: TextStyle(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.card,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour au menu',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showProductDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item['image'],
                  style: const TextStyle(fontSize: 35),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item['price']} DH',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: AppColors.mutedForeground),
                  onPressed: () {
                    context.read<ClientDataProvider>().removeFromCart(item);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (item['quantity'] > 1) {
                            item['quantity']--;
                            final idx = context
                                .read<ClientDataProvider>()
                                .cartItems
                                .indexOf(item);
                            if (idx != -1)
                              context
                                  .read<ClientDataProvider>()
                                  .updateCartItem(idx, item);
                          }
                        },
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                      Text(
                        '${item['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          item['quantity']++;
                          final idx = context
                              .read<ClientDataProvider>()
                              .cartItems
                              .indexOf(item);
                          if (idx != -1)
                            context
                                .read<ClientDataProvider>()
                                .updateCartItem(idx, item);
                        },
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.add,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détail de la commande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Sous-total', '${subtotal.toStringAsFixed(2)} DH'),
          const SizedBox(height: 8),
          _buildSummaryRow('Frais de livraison', 'Calculés après'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          _buildSummaryRow('Total Produits', '${subtotal.toStringAsFixed(2)} DH', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.foreground : AppColors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? AppColors.primary
                : (isDiscount ? AppColors.destructive : AppColors.foreground),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(double subtotal) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          )
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Produits',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  '${subtotal.toStringAsFixed(2)} DH',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  if (!context.read<ClientDataProvider>().isCurrentBusinessOpen) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Désolé, ce commerce est actuellement fermé.'),
                        backgroundColor: AppColors.destructive,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderConfirmationScreen()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Passer à la caisse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.card,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: AppColors.card, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
