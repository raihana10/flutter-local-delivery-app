import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/client_data_provider.dart';
import '../../../data/models/business_model.dart';
import '../../widgets/product_image_placeholder.dart';
import 'cart_screen.dart';

class PromotionProductScreen extends StatefulWidget {
  final Promotion promotion;

  const PromotionProductScreen({super.key, required this.promotion});

  @override
  State<PromotionProductScreen> createState() => _PromotionProductScreenState();
}

class _PromotionProductScreenState extends State<PromotionProductScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _originalPrice => widget.promotion.produit?.prix ?? 0.0;
  double get _discount => widget.promotion.pourcentage;
  double get _discountedPrice => _originalPrice * (1 - _discount / 100);
  double get _savings => _originalPrice - _discountedPrice;

  String get _businessName =>
      widget.promotion.produit?.business?.user?.nom ?? 'Commerce';
  String get _businessType =>
      widget.promotion.produit?.business?.type.value ?? 'restaurant';

  void _addToCart() {
    final produit = widget.promotion.produit;
    if (produit == null) return;

    final businessId = produit.idBusiness.toString();

    context.read<ClientDataProvider>().addToCart({
      'id': produit.id,
      'id_produit': produit.id,
      'id_business': businessId,
      'name': produit.nom,
      'options': '',
      'price': _discountedPrice,
      'original_price': _originalPrice,
      'discount_percent': _discount.toInt(),
      'quantity': _quantity,
      'image': produit.image,
      'type': produit.type,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_quantity}x ${produit.nom} ajouté au panier (-${_discount.toInt()}%)'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'VOIR PANIER',
          textColor: AppColors.accent,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final produit = widget.promotion.produit;
    if (produit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Produit introuvable')),
      );
    }

    final daysLeft = widget.promotion.dateFin.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // Hero AppBar
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.forest, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Product image or placeholder
                    Center(
                      child: (produit.image != null &&
                              produit.image!.startsWith('http'))
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                produit.image!,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    ProductImagePlaceholder(
                                  type: produit.type,
                                  size: 180,
                                ),
                              ),
                            )
                          : ProductImagePlaceholder(
                              type: produit.type,
                              size: 180,
                            ),
                    ),
                    // Discount badge
                    Positioned(
                      top: 100,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.destructive,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.destructive.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${_discount.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo time badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: daysLeft <= 2
                            ? AppColors.destructive.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: daysLeft <= 2
                                ? AppColors.destructive
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            daysLeft <= 0
                                ? 'Dernière chance !'
                                : daysLeft == 1
                                    ? 'Expire demain'
                                    : 'Encore $daysLeft jours',
                            style: TextStyle(
                              color: daysLeft <= 2
                                  ? AppColors.destructive
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Product name
                    Text(
                      produit.nom,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Business info
                    GestureDetector(
                      onTap: () {
                        // Could navigate to business detail
                      },
                      child: Row(
                        children: [
                          Icon(
                            _businessType == 'pharmacie'
                                ? LucideIcons.cross
                                : _businessType == 'super-marche'
                                    ? LucideIcons.store
                                    : LucideIcons.chefHat,
                            size: 16,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _businessName,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Price section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.tag,
                                    color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PRIX PROMOTIONNEL',
                                      style: TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_discountedPrice.toStringAsFixed(2)} MAD',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 3),
                                          child: Text(
                                            '${_originalPrice.toStringAsFixed(2)} MAD',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.mutedForeground,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor:
                                                  AppColors.destructive,
                                              decorationThickness: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.badgePercent,
                                    color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Vous économisez ${_savings.toStringAsFixed(2)} MAD !',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    if (produit.description != null &&
                        produit.description!.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        produit.description!,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quantity selector
                    const Text(
                      'Quantité',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(LucideIcons.minus, size: 18),
                            color: AppColors.primary,
                          ),
                          Container(
                            width: 50,
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foreground,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(LucideIcons.plus, size: 18),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom add to cart bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Total
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(_discountedPrice * _quantity).toStringAsFixed(2)} MAD',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Add to cart button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(LucideIcons.shoppingCart,
                      size: 18, color: Colors.white),
                  label: const Text(
                    'Ajouter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
