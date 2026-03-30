import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/business_model.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';
import 'support_screen.dart';
import 'restaurant_detail_screen.dart';
import 'generic_vertical_list_screen.dart';
import 'cart_screen.dart';
import 'client_profile_screen.dart';
import 'client_notifications_screen.dart';
import 'client_favorites_screen.dart';
import '../../../core/providers/client_data_provider.dart';
import '../../widgets/promotions_banner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MarketListScreen extends StatefulWidget {
  final int initialNavIndex;
  const MarketListScreen({super.key, this.initialNavIndex = 1});

  @override
  State<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends State<MarketListScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 1; // default to 'Rechercher'
  final TextEditingController _searchTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _promoPageController = PageController();

  bool _isMapViewOpen = false;
  double _maxDistance = 10.0;
  RangeValues _priceRange = const RangeValues(0, 500);
  final MapController _mapController = MapController();
  final LatLng _userLocation =
      const LatLng(35.5740, -5.3680); // Mock user location
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  bool _isSearching = false;
  int _currentPromoPage = 0;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _showAll = false;

  // Mock data
  List<Map<String, dynamic>> _allRestaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialNavIndex;
    _initializeMockData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchPromotions();
      }
    });

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _headerController.forward();
    _fabController.forward();

    // Fetch real data from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });

    _searchAnimationController.addListener(() {
      setState(() {});
    });

    // Auto-scroll promos
    _startPromoAutoScroll();
  }

  Future<void> _fetchData() async {
    await context.read<ProductProvider>().fetchBusinesses('super-marche');
    _mapBusinessesToMarkets();
  }

  void _mapBusinessesToMarkets() {
    final businesses = context.read<ProductProvider>().businesses;
    setState(() {
      _allRestaurants = businesses.map<Map<String, dynamic>>((b) {
        final biz = b as Business;
        return {
          'id': biz.id,
          'id_business': biz.id,
          'name': biz.user?.nom ?? 'Supermarché',
          'rating': 4.5,
          'time': '30-45 min',
          'image': Icons.shopping_cart,
          'pdp': biz.pdp,
          'distance': '1.5 km',
          'isOpen': biz.isOpen,
          'is_open': biz.isOpen,
          'category': 'all',
          'deliveryFee': '20 DH',
          'minOrder': '100 DH',
          'description': biz.description ?? 'Épicerie et produits frais',
          'cuisine': biz.description ?? 'Épicerie et produits frais',
          'app_user': {
            'nom': biz.user?.nom ?? 'Supermarché',
          }
        };
      }).toList();
      _filteredRestaurants = List.from(_allRestaurants);
    });
  }

  void _initializeMockData() {
    // Removed mock initialization.
    // _filteredRestaurants is now dynamically computed in `build` or handled on changes.
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });

    // Animation feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtré par: ${_getCategoryName(category)}'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        bool matchesCategory = _selectedCategory == 'all' ||
            restaurant['category'] == _selectedCategory;
        bool matchesSearch = _searchQuery.isEmpty ||
            restaurant['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            restaurant['cuisine']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        // Filter by distance
        double dist =
            double.parse(restaurant['distance'].toString().split(' ')[0]);
        bool matchesDistance = dist <= _maxDistance;

        // Filter by price (mocking minOrder as a proxy for price level)
        double price =
            double.parse(restaurant['minOrder'].toString().split(' ')[0]);
        bool matchesPrice =
            price >= _priceRange.start && price <= _priceRange.end;

        return matchesCategory &&
            matchesSearch &&
            matchesDistance &&
            matchesPrice;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtres',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _maxDistance = 10.0;
                            _priceRange = const RangeValues(0, 500);
                          });
                          _applyFilters();
                        },
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Distance Max (km)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxDistance,
                    min: 0.5,
                    max: 20,
                    divisions: 19,
                    label: '${_maxDistance.toStringAsFixed(1)} km',
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.secondary.withOpacity(0.2),
                    onChanged: (value) {
                      setModalState(() => _maxDistance = value);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Budget Min (MAD)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 500,
                    divisions: 10,
                    labels: RangeLabels('${_priceRange.start.round()} MAD',
                        '${_priceRange.end.round()} MAD'),
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.secondary.withOpacity(0.2),
                    onChanged: (values) {
                      setModalState(() => _priceRange = values);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Appliquer',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _performSearch() {
    _applyFilters();
    // Fermer le clavier après la recherche
    FocusScope.of(context).unfocus();

    // Animation feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Recherche: "${_searchQuery}" - ${_filteredRestaurants.length} résultats'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'all':
        return 'Tout';
      case 'epicerie':
        return 'Épicerie';
      case 'frais':
        return 'Frais';
      case 'boissons':
        return 'Boissons';
      case 'snacks':
        return 'Snacks';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all':
        return Icons.apps;
      case 'epicerie':
        return Icons.shopping_basket;
      case 'frais':
        return Icons.egg;
      case 'boissons':
        return Icons.local_drink;
      case 'snacks':
        return Icons.cookie;
      default:
        return Icons.shopping_cart;
    }
  }

  void _startPromoAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _promoPageController.hasClients) {
        final nextPage = (_currentPromoPage + 1) % 3;
        _promoPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _setCurrentPromoPage(nextPage);
        _startPromoAutoScroll();
      }
    });
  }

  void _setCurrentPromoPage(int page) {
    if (mounted) {
      setState(() {
        _currentPromoPage = page;
      });
    }
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _scrollController.dispose();
    _promoPageController.dispose();
    _headerController.dispose();
    _searchAnimationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final clientData = context.watch<ClientDataProvider>();
    
    // Prioritize businesses fetched from ProductProvider (Supabase) over failing legacy API
    final baseMarkets = _allRestaurants.isNotEmpty 
        ? _allRestaurants 
        : clientData.filteredSuperMarkets;
    
    _filteredRestaurants = baseMarkets.where((market) {
      final nameStr = (market['name'] ?? '').toString().toLowerCase();
      final cuisineStr = (market['cuisine'] ?? '').toString().toLowerCase();
      
      bool matchesSearch = _searchQuery.isEmpty || 
          nameStr.contains(_searchQuery.toLowerCase()) ||
          cuisineStr.contains(_searchQuery.toLowerCase());
          
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Animated Header
                AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - _headerAnimation.value) * 50),
                      child: Opacity(
                        opacity: _headerAnimation.value,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.9),
                                AppColors.secondary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Greeting and Location
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios,
                                          color: AppColors.textWhite),
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bonjour, ${user?.nom ?? 'Client'}',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textWhite,
                                                    height: 1.2,
                                                    letterSpacing: -0.5,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accent
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                      color: AppColors.accent
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.location_on,
                                                        color: AppColors.accent,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Consumer<ClientDataProvider>(
                                                        builder: (context, data, _) => Text(
                                                          '${data.currentCity}, Maroc',
                                                          style: TextStyle(
                                                            color:
                                                                AppColors.accent,
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ClientNotificationsScreen(),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accent,
                                                    borderRadius: BorderRadius.circular(16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors.accent.withOpacity(0.4),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      const Icon(
                                                        Icons.notifications_none,
                                                        color: AppColors.primary,
                                                        size: 24,
                                                      ),
                                                      Consumer<ClientDataProvider>(
                                                        builder: (context, data, _) {
                                                          final hasUnread = data.notifications.any((n) => n['lu'] == false);
                                                          if (!hasUnread) return const SizedBox.shrink();
                                                          return Positioned(
                                                            top: 8,
                                                            right: 8,
                                                            child: Container(
                                                              width: 8,
                                                              height: 8,
                                                              decoration: const BoxDecoration(
                                                                color: AppColors.destructive,
                                                                shape: BoxShape.circle,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                                                  );
                                                },
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                        color: AppColors.primary
                                                            .withOpacity(0.3)),
                                                  ),
                                                  child: const Icon(
                                                      Icons.directions_bike,
                                                      color:
                                                          AppColors.textWhite),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Animated Search Bar
                                AnimatedBuilder(
                                  animation: _searchAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 16),
                                          const Icon(Icons.search,
                                              color: AppColors.mutedForeground,
                                              size: 22),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchTextController,
                                              onTap: () {
                                                setState(() {
                                                  _isSearching = true;
                                                });
                                                _searchAnimationController
                                                    .forward();
                                              },
                                              onSubmitted: (value) {
                                                _performSearch();
                                              },
                                              onChanged: (val) => setState(() {
                                                _searchQuery = val;
                                                _applyFilters();
                                              }),
                                              decoration: InputDecoration(
                                                hintText: _isSearching
                                                    ? 'Rechercher un produit...'
                                                    : 'Rechercher...',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                              ),
                                            ),
                                          ),
                                          if (_isSearching)
                                            IconButton(
                                              icon: const Icon(Icons.clear,
                                                  color: AppColors
                                                      .mutedForeground),
                                              onPressed: () {
                                                _searchTextController.clear();
                                                setState(() {
                                                  _isSearching = false;
                                                  _searchQuery = '';
                                                });
                                                _applyFilters();
                                                _searchAnimationController
                                                    .reverse();
                                              },
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.tune,
                                                color: AppColors.primary),
                                            onPressed: _showFilterSheet,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                _isMapViewOpen
                                                    ? Icons.list
                                                    : Icons.map_outlined,
                                                color: AppColors.primary),
                                            onPressed: () => setState(() =>
                                                _isMapViewOpen =
                                                    !_isMapViewOpen),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),


                // Main Content
                Expanded(
                  child: _isMapViewOpen
                      ? _buildMapView()
                      : SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Promotional Banner
                              _buildPromotionalBanner(),

                              const SizedBox(height: 24),

                              // Quick Actions
                              _buildQuickActions(),

                              const SizedBox(height: 24),

                              // Promotions Section
                              Consumer<ProductProvider>(
                                builder: (context, provider, _) => _buildSectionTitle(
                                  'Promos du jour', 
                                  'Voir tout', 
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GenericVerticalListScreen(
                                        title: 'Promotions',
                                        items: provider.promotions,
                                        category: 'promos',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const PromotionsBanner(),

                              const SizedBox(height: 24),

                              // Results count
                              if (_searchQuery.isNotEmpty ||
                                  _selectedCategory != 'all')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    '${_filteredRestaurants.length} magasin${_filteredRestaurants.length > 1 ? 's' : ''} trouvé${_filteredRestaurants.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                              // Nearby Restaurants Section
                              _buildSectionTitle(
                                  'Magasins proches', 'Voir tout', () {}),
                              const SizedBox(height: 12),

                              // Display message if no restaurants found
                              if (_filteredRestaurants.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        size: 64,
                                        color: AppColors.mutedForeground
                                            .withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun magasin trouvé',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.foreground,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Essayez de modifier vos filtres ou votre recherche',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedCategory = 'all';
                                            _searchQuery = '';
                                            _searchTextController.clear();
                                            _applyFilters();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textWhite,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                            'Réinitialiser les filtres'),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredRestaurants.length,
                                  itemBuilder: (context, index) {
                                    return _buildRestaurantCard(
                                        _filteredRestaurants[index], index);
                                  },
                                ),

                              const SizedBox(height: 120), // Bottom nav padding
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supermarchés proches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Faites vos courses sans vous déplacer',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Historique',
                Icons.history,
                AppColors.primary,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Favoris',
                Icons.favorite,
                AppColors.destructive,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClientFavoritesScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Support',
                Icons.support_agent,
                AppColors.secondary,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SupportScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      String label, IconData icon, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive ? AppColors.accent : AppColors.border,
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color:
                      isActive ? AppColors.primary : AppColors.mutedForeground,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, String actionText, VoidCallback onActionTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
          if (actionText.isNotEmpty)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.gold,
                    size: 12,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildRestaurantCard(Map<String, dynamic> marketInfo, int index) {
    final businessUser = marketInfo['app_user'] ?? {};
    final idBusiness = marketInfo['id_business'] ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantDetailScreen(
                  restaurantName: businessUser['nom'] ?? 'Magasin',
                  heroTag: 'market_${idBusiness}_$index',
                  businessId: idBusiness.toString(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withOpacity(0.08),
          highlightColor: AppColors.primary.withOpacity(0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Restaurant Image
                  Hero(
                    tag: 'market_${idBusiness}_$index',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.background,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: marketInfo['pdp'] != null 
                            ? DecorationImage(
                                image: NetworkImage(marketInfo['pdp']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: marketInfo['pdp'] == null 
                          ? Center(
                              child: Text(
                                '🛒',
                                style: const TextStyle(fontSize: 32),
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Restaurant Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                businessUser['nom'] ?? 'Magasin',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.foreground,
                                  height: 1.2,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            Consumer<ClientDataProvider>(
                                builder: (context, clientData, _) {
                              final id = marketInfo['id_business']
                                      ?.toString() ??
                                  '0';
                              final isFav = clientData.isFavoriteBusiness(id);
                              return IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? AppColors.destructive : AppColors.mutedForeground,
                                  size: 22,
                                ),
                                onPressed: () => clientData.toggleFavorite(id),
                              );
                            }),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (marketInfo['is_open'] == true)
                                    ? Colors.green.withOpacity(0.1)
                                    : AppColors.destructive.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (marketInfo['is_open'] == true)
                                    ? 'Ouvert'
                                    : 'Fermé',
                                style: TextStyle(
                                  color: (marketInfo['is_open'] == true)
                                      ? Colors.green
                                      : AppColors.destructive,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.accent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '4.4',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${marketInfo['temps_preparation'] ?? 30} min',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppColors.secondary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '2.0 km',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                marketInfo['description'] ?? 'Supermarché et épicerie',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Livraison 15 DH',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Accueil', 0),
          _buildNavItem(Icons.shopping_cart, 'Panier', 1),
          _buildNavItem(Icons.history, 'Historique', 2),
          _buildNavItem(Icons.person, 'Profil', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.of(context).pop();
          return;
        }

        setState(() {
          _currentIndex = index;
        });

        Widget? targetScreen;
        switch (index) {
          case 1:
            targetScreen = const CartScreen();
            break;
          case 2:
            targetScreen = const OrderHistoryScreen();
            break;
          case 3:
            targetScreen = const ClientProfileScreen();
            break;
        }

        if (targetScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetScreen!),
          ).then((_) {
            if (mounted) {
              setState(() {
                _currentIndex = 0; // Return visual state to current screen icon
              });
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isActive ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.accent : AppColors.secondary,
                  size: 24,
                ),
                if (index == 1) // Cart icon with badge
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Consumer<ClientDataProvider>(
                      builder: (context, cart, _) {
                        final count = cart.cartItems.length;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.accent : AppColors.secondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.livraison.app.frontend',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.person_pin_circle,
                      color: Colors.white, size: 20),
                ),
              ),
              ..._filteredRestaurants.map((res) {
                double lat = _userLocation.latitude +
                    (double.parse(res['distance'].split(' ')[0]) * 0.005);
                double lng = _userLocation.longitude +
                    (double.parse(res['distance'].split(' ')[0]) * 0.005);
                return Marker(
                  point: LatLng(lat, lng),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(res['name']))),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ]),
                      child: Center(
                          child: Icon(res['image'] as IconData,
                              color: AppColors.primary, size: 24)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
