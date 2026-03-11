import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<Map<String, dynamic>> _cartItems = [
    {
      'name': 'Menu Maxi Burger',
      'options': 'Taille standard, Sauce Algérienne',
      'price': 65.0,
      'quantity': 2,
      'image': '🍔'
    },
    {
      'name': 'Pizza Marguerita',
      'options': 'Grande (+15 DH)',
      'price': 60.0,
      'quantity': 1,
      'image': '🍕'
    },
  ];

  final TextEditingController _couponController = TextEditingController();
  bool _isCouponApplied = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // ─── Product Detail Dialog ───────────────────────────────────────────────────

  void _showProductDetail(Map<String, dynamic> item) {
    final List<String> availableOptions = [
      'Taille standard',
      'Grande (+15 DH)',
      'Sauce Algérienne',
      'Sauce Harissa',
      'Extra fromage (+8 DH)',
      'Sans oignon',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        int tempQty = item['quantity'] as int;
        List<String> selectedOptions = (item['options'] as String)
            .split(', ')
            .where((o) => o.isNotEmpty)
            .toList();

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

                    // Options section
                    const Text(
                      'Options',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableOptions.map((opt) {
                        final isSelected = selectedOptions.contains(opt);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedOptions.remove(opt);
                              } else {
                                selectedOptions.add(opt);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              opt,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.card
                                    : AppColors.foreground,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
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

                    // Action buttons — Column avoids Expanded-in-Row inside ScrollView
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            item['quantity'] = tempQty;
                            item['options'] = selectedOptions.join(', ');
                          });
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
                          setState(() => _cartItems.remove(item));
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.destructive, size: 18),
                        label: const Text("Supprimer l'article",
                            style:
                                TextStyle(color: AppColors.destructive)),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: AppColors.destructive),
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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    double subtotal =
        _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    double deliveryFee = 10.0;
    double discount = _isCouponApplied ? subtotal * 0.1 : 0;
    double total = subtotal + deliveryFee - discount;

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
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ..._cartItems.map((item) => _buildCartItem(item)),
                      const SizedBox(height: 24),
                      _buildCouponSection(),
                      const SizedBox(height: 24),
                      _buildOrderSummary(subtotal, deliveryFee, discount, total),
                    ],
                  ),
                ),
                _buildCheckoutBar(total),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Parcourir les restaurants',
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
                  if (item['options'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['options'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
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
                    setState(() {
                      _cartItems.remove(item);
                    });
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
                          setState(() {
                            if (item['quantity'] > 1) item['quantity']--;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child:
                              Icon(Icons.remove, size: 16, color: AppColors.primary),
                        ),
                      ),
                      Text(
                        '${item['quantity']}',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            item['quantity']++;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _couponController,
              decoration: const InputDecoration(
                hintText: 'Code promo',
                border: InputBorder.none,
                isDense: true,
              ),
              enabled: !_isCouponApplied,
            ),
          ),
          if (_isCouponApplied)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.destructive),
              onPressed: () {
                setState(() {
                  _isCouponApplied = false;
                  _couponController.clear();
                });
              },
            )
          else
            TextButton(
              onPressed: () {
                if (_couponController.text.isNotEmpty) {
                  setState(() {
                    _isCouponApplied = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Coupon appliqué avec succès!'),
                        backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Appliquer',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
      double subtotal, double deliveryFee, double discount, double total) {
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
          _buildSummaryRow('Sous-total', '$subtotal DH'),
          const SizedBox(height: 8),
          _buildSummaryRow('Frais de livraison', '$deliveryFee DH'),
          if (_isCouponApplied) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Remise (10%)', '-$discount DH',
                isDiscount: true),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          _buildSummaryRow('Total', '$total DH', isTotal: true),
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

  Widget _buildCheckoutBar(double total) {
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
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  '$total DH',
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
