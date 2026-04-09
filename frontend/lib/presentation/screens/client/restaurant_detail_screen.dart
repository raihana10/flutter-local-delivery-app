import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/client_data_provider.dart';
import '../../widgets/product_image_placeholder.dart';
import '../../../core/providers/product_provider.dart';
import '../../../data/models/business_model.dart';
import 'cart_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantName;
  final String heroTag;
  final String businessId;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantName,
    required this.heroTag,
    required this.businessId,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingReviews = true;
  bool _isLoadingProducts = true;
  bool _isLoadingDetails = true;
  List<dynamic> _reviews = [];
  List<dynamic> _products = [];
  Map<String, dynamic>? _businessInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
      _fetchReviews();
      _fetchProducts();
    });
  }

  Future<void> _fetchDetails() async {
    final provider = context.read<ClientDataProvider>();
    final details = await provider.getBusinessDetails(widget.businessId);
    if (mounted) {
      print('Details for ${widget.businessId}: ${details?['type_business']}');
      setState(() {
        _businessInfo = details;
        _isLoadingDetails = false;
      });
      provider.setCurrentBusiness(details);
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final provider = context.read<ClientDataProvider>();
      final reviews = await provider.getBusinessReviews(widget.businessId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final bizId = int.tryParse(widget.businessId) ?? 0;
      final productProvider = context.read<ProductProvider>();
      await productProvider.fetchProductsByBusiness(bizId);
      
      if (mounted) {
        setState(() {
          _products = productProvider.businessProducts.map((p) => {
            'id_produit': p.id,
            'nom_produit': p.nom,
            'description': p.description,
            'prix_unitaire': p.prix,
            'image': p.image,
            'type_produit': p.type,
            'deleted_at': p.deletedAt,
            'promotion': p.promotion,
          }).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  String getHeaderEmoji() {
    String type = _businessInfo?['type_business'] ?? 'restaurant';
    if (type == 'pharmacie') return '💊';
    if (type == 'super-marche') return '🛒';
    return '🍽️';
  }

  String getTabText() {
    String type = _businessInfo?['type_business'] ?? 'restaurant';
    if (type == 'pharmacie') return 'Médicaments';
    if (type == 'super-marche') return 'Rayons';
    return 'Menu';
  }

  IconData getTabIcon() {
    String type = _businessInfo?['type_business'] ?? 'restaurant';
    if (type == 'pharmacie') return Icons.medical_services;
    if (type == 'super-marche') return Icons.shopping_basket;
    return Icons.restaurant_menu;
  }

  String _getAddress() {
    if (_businessInfo == null) return '';
    final appUser = _businessInfo!['app_user'] ?? {};
    final userAdresse = appUser['user_adresse'] as List<dynamic>? ?? [];
    if (userAdresse.isEmpty) return 'Adresse non renseignée';
    final adresse = userAdresse[0]['adresse'] ?? {};
    
    final ville = adresse['ville'] ?? '';
    final quartier = adresse['quartier'] ?? '';
    final details = adresse['adresse_detaillee'] ?? '';
    
    final String complete = [details, quartier, ville].where((s) => s.toString().isNotEmpty).join(', ');
    return complete.isEmpty ? 'Adresse non renseignée' : complete;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int reviewCount = _reviews.length;
    final double averageRating = reviewCount == 0 ? 0.0 : 
      _reviews.map((r) => (r['evaluation'] as num?) ?? 0).reduce((a, b) => a + b) / reviewCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar avec image du restaurant
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: AppColors.card),
            actions: [
              Consumer<ClientDataProvider>(
                builder: (context, provider, child) {
                  final idBusiness = int.tryParse(widget.businessId) ?? 0;
                  final isFav = provider.isFavorite(idBusiness);
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.destructive : AppColors.card,
                      ),
                      onPressed: () {
                        if (idBusiness > 0) {
                          provider.toggleFavorite(idBusiness);
                        }
                      },
                    ),
                  );
                }
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Center(
                    child: (_businessInfo != null && _businessInfo!['pdp'] != null && _businessInfo!['pdp'].toString().startsWith('http'))
                      ? Image.network(
                          _businessInfo!['pdp'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Text(
                            getHeaderEmoji(),
                            style: const TextStyle(fontSize: 80),
                          ),
                        )
                      : Text(
                          getHeaderEmoji(),
                          style: const TextStyle(fontSize: 80),
                        ),
                  ),
                ),
              ),
            ),
          ),

          // Informations du restaurant
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurantName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.star, '${averageRating.toStringAsFixed(1)} ($reviewCount avis)', AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: AppColors.mutedForeground),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getAddress(),
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _businessInfo?['description'] ?? '',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                ],
              ),
            ),
          ),

          // Tabs for Menu and Reviews
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.mutedForeground,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: getTabText(), icon: Icon(getTabIcon())),
                  Tab(text: 'Avis (${_reviews.length})', icon: const Icon(Icons.star_rate)),
                ],
              ),
            ),
          ),

          // Content of Tabs using SliverFillRemaining
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Menu Tab
                _isLoadingProducts
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _products.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Aucun produit disponible pour le moment.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedForeground)),
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index] as Map<String, dynamic>;
                          return _buildMenuItem({
                            'id': p['id_produit'],
                            'name': p['nom_produit'] ?? 'Produit',
                            'desc': p['description'] ?? '',
                            'price': p['prix_unitaire'] ?? 0,
                            'image': p['image'],
                            'type': p['type_produit'] ?? 'meal',
                            'promotion': p['promotion'],
                          });
                        },
                      ),
                
                // Reviews Tab
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Cart Button
      floatingActionButton: Consumer<ClientDataProvider>(
        builder: (context, clientData, child) {
          final count = clientData.cartItems.length;
          if (count == 0) return const SizedBox();
          return FloatingActionButton.extended(
            backgroundColor: AppColors.accent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: const Icon(Icons.shopping_cart, color: AppColors.primary),
            label: Text(
              'Voir le panier ($count)',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCategory(Map<String, dynamic> category) {
    final items = category['items'] as List<dynamic>;
    
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category['title'],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildMenuItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        _showProductOptions(item);
      },
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
        child: Opacity(
          opacity: (_businessInfo?['is_open'] == true) ? 1.0 : 0.6,
          child: Row(
            children: [
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
                    item['desc'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final promo = item['promotion'];
                      final double originalPrice = double.tryParse(item['price'].toString()) ?? 0.0;
                      
                      if (promo != null && promo is Promotion) {
                        final double promoPrice = originalPrice * (1 - (promo.pourcentage / 100));
                        return Row(
                          children: [
                            Text(
                              '${promoPrice.toStringAsFixed(1)} DH',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.destructive,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${originalPrice.toStringAsFixed(1)} DH',
                              style: const TextStyle(
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        );
                      }
                      
                      return Text(
                        '${item['price']} DH',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                image: (item['image'] != null && item['image'].toString().startsWith('http'))
                    ? DecorationImage(image: NetworkImage(item['image'].toString()), fit: BoxFit.cover)
                    : null,
              ),
              child: (item['image'] == null || !item['image'].toString().startsWith('http'))
                ? Center(
                    child: Text(
                      getHeaderEmoji(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  )
                : null,
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showProductOptions(Map<String, dynamic> item) {
    int quantity = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (innerModalContext, setModalState) {
          final promo = item['promotion'];
          final double originalPrice = double.tryParse(item['price'].toString()) ?? 0.0;
          double unitPrice = originalPrice;
          
          if (promo != null && promo is Promotion) {
            unitPrice = originalPrice * (1 - (promo.pourcentage / 100));
          }
          
          final double totalPrice = unitPrice * quantity;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedForeground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Image & Title
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                    image: (item['image'] != null && item['image'].toString().startsWith('http'))
                        ? DecorationImage(image: NetworkImage(item['image'].toString()), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (item['image'] == null || !item['image'].toString().startsWith('http'))
                    ? Center(child: Text(getHeaderEmoji(), style: const TextStyle(fontSize: 60)))
                    : null,
                ),
                const SizedBox(height: 20),
                Text(
                  item['name'] ?? 'Produit',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                 Builder(
                  builder: (context) {
                    final promo = item['promotion'];
                    final double originalPrice = double.tryParse(item['price'].toString()) ?? 0.0;
                    
                    if (promo != null && promo is Promotion) {
                      final double promoPrice = originalPrice * (1 - (promo.pourcentage / 100));
                      return Column(
                         children: [
                            Text(
                              '${promoPrice.toStringAsFixed(1)} DH',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.destructive,
                              ),
                            ),
                            Text(
                              '${originalPrice.toStringAsFixed(1)} DH',
                              style: const TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                         ],
                      );
                    }
                    return Text(
                      '${item['price']} DH',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    );
                  }
                ),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        item['desc'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Add to Cart Button
                Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
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
                  ),
                  child: Row(
                    children: [
                      // Quantity
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: AppColors.primary),
                              onPressed: () {
                                if (quantity > 1) {
                                  setModalState(() => quantity--);
                                }
                              },
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foreground,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: AppColors.primary),
                              onPressed: () {
                                setModalState(() => quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Add Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (_businessInfo?['is_open'] == true) ? () {
                            context.read<ClientDataProvider>().addToCart({
                              'id': item['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000, 
                              'id_produit': item['id'],
                              'id_business': widget.businessId,
                              'name': item['name'],
                              'options': '', // Removed options tracking
                              'price': unitPrice,
                              'quantity': quantity,
                              'image': item['image'] ?? '🍽️',
                              'business_id': widget.businessId, // Add business_id for hybrid order detection
                            });
                            Navigator.pop(innerModalContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${quantity}x ${item['name']} ajouté au panier'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                action: SnackBarAction(
                                  label: 'VOIR',
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
                          } : null,
                          child: Text(
                            (_businessInfo?['is_open'] == true) ? 'Ajouter - $totalPrice DH' : 'Fermé actuellement',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }



  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final double averageRating = _reviews.isEmpty ? 0.0 : 
      _reviews.map((r) => (r['evaluation'] as num?) ?? 0).reduce((a, b) => a + b) / _reviews.length;
    
    int getRatingCount(int stars) {
      return _reviews.where((r) => ((r['evaluation'] as num?) ?? 0).round() == stars).length;
    }

    return ListView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      children: [
        // Review Stats (Header)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(averageRating >= 1 ? Icons.star : Icons.star_border, color: AppColors.gold, size: 20),
                      Icon(averageRating >= 2 ? Icons.star : Icons.star_border, color: AppColors.gold, size: 20),
                      Icon(averageRating >= 3 ? Icons.star : Icons.star_border, color: AppColors.gold, size: 20),
                      Icon(averageRating >= 4 ? Icons.star : Icons.star_border, color: AppColors.gold, size: 20),
                      Icon(averageRating >= 5 ? Icons.star : averageRating >= 4.5 ? Icons.star_half : Icons.star_border, color: AppColors.gold, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sur ${_reviews.length} avis',
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, _reviews.isEmpty ? 0 : getRatingCount(5) / _reviews.length),
                    _buildRatingBar(4, _reviews.isEmpty ? 0 : getRatingCount(4) / _reviews.length),
                    _buildRatingBar(3, _reviews.isEmpty ? 0 : getRatingCount(3) / _reviews.length),
                    _buildRatingBar(2, _reviews.isEmpty ? 0 : getRatingCount(2) / _reviews.length),
                    _buildRatingBar(1, _reviews.isEmpty ? 0 : getRatingCount(1) / _reviews.length),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Add Review Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary),
            ),
            elevation: 0,
          ),
          onPressed: () {
            _showAddReviewBottomSheet();
          },
          icon: const Icon(Icons.rate_review),
          label: const Text('Laisser un avis', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        
        const SizedBox(height: 24),
        
        // Review List
        if (_reviews.isEmpty)
           const Padding(
             padding: EdgeInsets.symmetric(vertical: 32),
             child: Center(
               child: Text('Aucun avis pour le moment', style: TextStyle(color: AppColors.mutedForeground)),
             ),
           )
        else
          ..._reviews.map((review) => _buildReviewItem(review)).toList(),
      ],
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$stars', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mutedForeground)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.border,
              color: AppColors.gold,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(dynamic review) {
    final client = review['client'] ?? {};
    final user = client['app_user'] ?? {};
    final userName = (user['nom'] != null || user['prenom'] != null)
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Client Anonyme';
    final date = review['created_at'] != null 
        ? DateTime.tryParse(review['created_at'].toString()) 
        : null;
    final dateString = date != null ? '${date.day}/${date.month}/${date.year}' : 'Récemment';
    final rating = (review['evaluation'] as num?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                dateString,
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: AppColors.gold,
                size: 16,
              );
            }),
          ),
          if (review['commentaire'] != null && review['commentaire'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['commentaire'].toString(),
              style: const TextStyle(color: AppColors.foreground, height: 1.4),
            ),
          ]
        ],
      ),
    );
  }

  final TextEditingController _commentController = TextEditingController();

  void _showAddReviewBottomSheet() {
    int selectedRating = 5;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // important for keyboard
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Laisser un avis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.foreground)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: AppColors.gold,
                          size: 40,
                        ),
                        onPressed: () {
                          setModalState(() => selectedRating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Partagez votre expérience...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        setState(() => _isLoadingReviews = true);
                        Navigator.pop(context);
                        final success = await context.read<ClientDataProvider>().addBusinessReview(
                          widget.businessId,
                          selectedRating,
                          _commentController.text,
                        );
                        if (success) {
                          _commentController.clear();
                          await _fetchReviews();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avis ajouté avec succès !')));
                        } else {
                          setState(() => _isLoadingReviews = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'ajout de l\'avis.')));
                        }
                      },
                      child: const Text('Envoyer', style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
