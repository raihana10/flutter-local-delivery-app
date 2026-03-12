import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/client_data_provider.dart';
import 'cart_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantName;
  final String heroTag;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantName,
    required this.heroTag,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _menuCategories = [
    {
      'title': 'Populaire',
      'items': [
        {'name': 'Menu Maxi Burger', 'desc': 'Burger double steak, frites, boisson 33cl', 'price': 65.0, 'image': '🍔'},
        {'name': 'Pizza Marguerita', 'desc': 'Sauce tomate, mozzarella, basilic frais', 'price': 45.0, 'image': '🍕'},
      ]
    },
    {
      'title': 'Burgers',
      'items': [
        {'name': 'Cheese Burger', 'desc': 'Steak, cheddar, salade, tomate, oignon', 'price': 40.0, 'image': '🍔'},
        {'name': 'Chicken Burger', 'desc': 'Poulet croustillant, cheddar, salade', 'price': 45.0, 'image': '🍔'},
      ]
    },
    {
      'title': 'Desserts',
      'items': [
        {'name': 'Tiramisu', 'desc': 'Fait maison, café et mascarpone', 'price': 25.0, 'image': '🍰'},
        {'name': 'Fondant au chocolat', 'desc': 'Cœur coulant, glace vanille', 'price': 30.0, 'image': '🧁'},
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
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
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
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
                    child: Text(
                      '🍽️',
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
                      _buildInfoBadge(Icons.star, '4.8 (120 avis)', AppColors.accent),
                      const SizedBox(width: 12),
                      _buildInfoBadge(Icons.access_time, '25-35 min', AppColors.primary),
                      const SizedBox(width: 12),
                      _buildInfoBadge(Icons.delivery_dining, '10 DH', AppColors.secondary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Spécialités italiennes, pizzas au feu de bois et pâtes fraîches.',
                    style: TextStyle(
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
                tabs: const [
                  Tab(text: 'Menu', icon: Icon(Icons.restaurant_menu)),
                  Tab(text: 'Avis (120)', icon: Icon(Icons.star_rate)),
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
                ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _menuCategories.length,
                  itemBuilder: (context, index) {
                    return _buildMenuCategory(_menuCategories[index]);
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
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item['image'],
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ],
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final double basePrice = double.tryParse(item['price'].toString()) ?? 0.0;
          final double totalPrice = basePrice * quantity;
          
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
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      item['image'] ?? '🍽️',
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
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
                Text(
                  '${item['price']} DH',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
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
                          onPressed: () {
                            context.read<ClientDataProvider>().addToCart({
                              'id': item['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000, 
                              'name': item['name'],
                              'options': '', // Removed options tracking
                              'price': basePrice,
                              'quantity': quantity,
                              'image': item['image'] ?? '🍽️',
                            });
                            Navigator.pop(context);
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
                          },
                          child: Text(
                            'Ajouter - $totalPrice DH',
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
    final List<Map<String, dynamic>> reviews = [
      {
        'user': 'Karim M.',
        'rating': 5,
        'date': 'Il y a 2 jours',
        'comment': 'Excellent burger, très copieux et la livraison a été super rapide. Je recommande !',
      },
      {
        'user': 'Sara B.',
        'rating': 4,
        'date': 'Il y a 1 semaine',
        'comment': 'Très bon, mais les frites étaient un peu froides. Sinon parfait.',
      },
      {
        'user': 'Amine T.',
        'rating': 5,
        'date': 'Il y a 2 semaines',
        'comment': 'Ma pizzeria préférée sur Tétouan. Jamais déçu !',
      },
    ];

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
              const Column(
                children: [
                  Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.gold, size: 20),
                      Icon(Icons.star, color: AppColors.gold, size: 20),
                      Icon(Icons.star, color: AppColors.gold, size: 20),
                      Icon(Icons.star, color: AppColors.gold, size: 20),
                      Icon(Icons.star_half, color: AppColors.gold, size: 20),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sur 120 avis',
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.8),
                    _buildRatingBar(4, 0.15),
                    _buildRatingBar(3, 0.05),
                    _buildRatingBar(2, 0.0),
                    _buildRatingBar(1, 0.0),
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
        ...reviews.map((review) => _buildReviewItem(review)).toList(),
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

  Widget _buildReviewItem(Map<String, dynamic> review) {
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
                review['user'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                review['date'],
                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review['rating'] ? Icons.star : Icons.star_border,
                color: AppColors.gold,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'],
            style: const TextStyle(color: AppColors.foreground, height: 1.4),
          ),
        ],
      ),
    );
  }

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
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // push above keyboard
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Évaluer ce restaurant',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Star Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 40,
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: AppColors.gold,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Comment Text Field
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Partagez votre expérience (optionnel)',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Merci pour votre avis !')),
                      );
                    },
                    child: const Text(
                      'Envoyer',
                      style: TextStyle(color: AppColors.card, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            );
          }
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
