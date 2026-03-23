import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'restaurant_detail_screen.dart';
import 'cart_screen.dart';
import 'client_profile_screen.dart';
import 'client_notifications_screen.dart';
import 'client_favorites_screen.dart';
import '../../../core/providers/client_data_provider.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final TextEditingController _searchTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _promoPageController = PageController();

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
    // Removed local mock init since data comes from provider now

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

    _searchAnimationController.addListener(() {
      setState(() {});
    });

    // Auto-scroll promos
    _startPromoAutoScroll();
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
    // Rely on build method filtering or provider changes instead of setting state directly here on _filteredRestaurants.
    // Call setState to rebuild UI with current query and category
    setState(() {});
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
      case 'burgers':
        return 'Burgers';
      case 'asian':
        return 'Asiatique';
      case 'healthy':
        return 'Healthy';
      case 'desserts':
        return 'Desserts';
      case 'drinks':
        return 'Boissons';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all':
        return Icons.apps;
      case 'burgers':
        return Icons.lunch_dining;
      case 'asian':
        return Icons.set_meal;
      case 'healthy':
        return Icons.health_and_safety;
      case 'desserts':
        return Icons.cake;
      case 'drinks':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
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
    
    // Convert API data to map format and apply search query locally.
    // In production, filtering should probably be done effectively either via provider sorting 
    // or by backend endpoints passing '?search=' and '?category='. 
    final baseRestaurants = clientData.filteredRestaurants;
    
    _filteredRestaurants = baseRestaurants.where((restaurant) {
      final businessUser = restaurant['app_user'] ?? {};
      final nameStr = (businessUser['nom'] ?? '').toString().toLowerCase();
      // Category is mocked as restaurant type is uniform for now
      // The backend will handle 'category' mapping later (e.g. types of cuisines) if added to the Database.
      bool matchesSearch = _searchQuery.isEmpty || nameStr.contains(_searchQuery.toLowerCase());
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
                                                AnimatedSwitcher(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  child: Row(
                                                    key: ValueKey(user?.nom),
                                                    children: [
                                                      Text(
                                                        'Bonjour, ${user?.nom ?? 'Client'}',
                                                        style: const TextStyle(
                                                          fontSize: 28,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .textWhite,
                                                          height: 1.2,
                                                          letterSpacing: -0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons.waving_hand,
                                                        color: AppColors.accent,
                                                        size: 28,
                                                      ),
                                                    ],
                                                  ),
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
                                              PopupMenuButton<String>(
                                                onSelected: (value) async {
                                                  if (value == 'logout') {
                                                    await context
                                                        .read<AuthProvider>()
                                                        .logout();
                                                    if (mounted) {
                                                      Navigator.of(context)
                                                          .pushReplacementNamed(
                                                              '/');
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'logout',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.logout,
                                                            color: Colors.red,
                                                            size: 20),
                                                        SizedBox(width: 8),
                                                        Text('Déconnexion'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
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
                                                      Icons.person,
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
                                      child: TextField(
                                        controller: _searchTextController,
                                        onTap: () {
                                          setState(() {
                                            _isSearching = true;
                                          });
                                          _searchAnimationController.forward();
                                        },
                                        onSubmitted: (value) {
                                          _performSearch();
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: _isSearching
                                              ? 'Rechercher un restaurant, un plat...'
                                              : 'Que désirez-vous manger aujourd\'hui ?',
                                          hintStyle: TextStyle(
                                            color: AppColors.mutedForeground
                                                .withOpacity(0.7),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          prefixIcon: Container(
                                            padding: const EdgeInsets.all(12),
                                            child: Icon(
                                              Icons.search,
                                              color: _isSearching
                                                  ? AppColors.primary
                                                  : AppColors.mutedForeground,
                                              size: 22,
                                            ),
                                          ),
                                          suffixIcon: _searchAnimation.value >
                                                  0.5
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.search,
                                                        color:
                                                            AppColors.primary,
                                                        size: 22,
                                                      ),
                                                      onPressed: _performSearch,
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.clear,
                                                        color: AppColors
                                                            .mutedForeground,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _searchTextController
                                                            .clear();
                                                        setState(() {
                                                          _isSearching = false;
                                                          _searchQuery = '';
                                                        });
                                                        _applyFilters();
                                                        _searchAnimationController
                                                            .reverse();
                                                      },
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                        ),
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

                // Category Chips
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildCategoryChip(
                          'Tout',
                          _getCategoryIcon('all'),
                          _selectedCategory == 'all',
                          () => _filterByCategory('all')),
                      _buildCategoryChip(
                          'Burgers',
                          _getCategoryIcon('burgers'),
                          _selectedCategory == 'burgers',
                          () => _filterByCategory('burgers')),
                      _buildCategoryChip(
                          'Asiatique',
                          _getCategoryIcon('asian'),
                          _selectedCategory == 'asian',
                          () => _filterByCategory('asian')),
                      _buildCategoryChip(
                          'Healthy',
                          _getCategoryIcon('healthy'),
                          _selectedCategory == 'healthy',
                          () => _filterByCategory('healthy')),
                      _buildCategoryChip(
                          'Desserts',
                          _getCategoryIcon('desserts'),
                          _selectedCategory == 'desserts',
                          () => _filterByCategory('desserts')),
                      _buildCategoryChip(
                          'Boissons',
                          _getCategoryIcon('drinks'),
                          _selectedCategory == 'drinks',
                          () => _filterByCategory('drinks')),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
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
                        _buildSectionTitle(
                            'Promos du jour', 'Voir tout', () {}),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: PageView.builder(
                            controller: _promoPageController,
                            onPageChanged: (page) {
                              _setCurrentPromoPage(page);
                            },
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              return _buildPromoCard(index);
                            },
                          ),
                        ),

                        // Page Indicator
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPromoPage == index ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPromoPage == index
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Results count
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'all')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${_filteredRestaurants.length} restaurant${_filteredRestaurants.length > 1 ? 's' : ''} trouvé${_filteredRestaurants.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Nearby Restaurants Section
                        _buildSectionTitle(
                            'Restaurants proches', !_showAll ? 'Voir tout' : '', () {
                              setState(() {
                                _showAll = true;
                              });
                            }),
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
                                  'Aucun restaurant trouvé',
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child:
                                      const Text('Réinitialiser les filtres'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _showAll ? _filteredRestaurants.length : min(_filteredRestaurants.length, 3),
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
              Icons.storefront,
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
                  'Restaurants proches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commandez chez les meilleurs restaurants de votre ville',
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
                () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Favoris',
                Icons.favorite,
                AppColors.destructive,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientFavoritesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Support',
                Icons.support_agent,
                AppColors.secondary,
                () {},
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

  Widget _buildPromoCard(int index) {
    final promos = [
      {
        'title': 'Pizza 50%',
        'subtitle': 'Pizza Palace',
        'color': AppColors.destructive,
        'icon': Icons.local_pizza
      },
      {
        'title': 'Burger -20%',
        'subtitle': 'Burger House',
        'color': AppColors.accent,
        'icon': Icons.lunch_dining
      },
      {
        'title': 'Sushi -30%',
        'subtitle': 'Sushi Bar',
        'color': AppColors.primary,
        'icon': Icons.set_meal
      },
    ];

    final promo = promos[index % promos.length];

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to promo details
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background gradient
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            promo['color'] as Color,
                            (promo['color'] as Color).withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              promo['icon'] as IconData,
                              color: promo['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              promo['title'] as String,
                              style: TextStyle(
                                color: promo['color'] as Color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        promo['subtitle'] as String,
                        style: const TextStyle(
                          color: AppColors.card,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.card.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Valable jusqu\'au 31 Mars',
                          style: TextStyle(
                            color: AppColors.card.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurantInfo, int index) {
      final businessUser = restaurantInfo['app_user'] ?? {};
      final String name = businessUser['nom'] ?? 'Restaurant Inconnu';
      final String idBusiness = restaurantInfo['id_business']?.toString() ?? '0';

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
                  restaurantName: businessUser['nom'] ?? 'Restaurant',
                  heroTag: 'restaurant_${idBusiness}_$index',
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
                    tag: 'restaurant_${idBusiness}_$index',
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
                        image: restaurantInfo['pdp'] != null 
                            ? DecorationImage(
                                image: NetworkImage(restaurantInfo['pdp']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: restaurantInfo['pdp'] == null 
                          ? Center(
                              child: Text(
                                '🍔',
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
                                businessUser['nom'] ?? 'Restaurant',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.foreground,
                                  height: 1.2,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (restaurantInfo['is_open'] == true)
                                    ? Colors.green.withOpacity(0.1)
                                    : AppColors.destructive.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (restaurantInfo['is_open'] == true)
                                    ? 'Ouvert'
                                    : 'Fermé',
                                style: TextStyle(
                                  color: (restaurantInfo['is_open'] == true)
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
                                    '4.5',
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
                                    '${restaurantInfo['temps_preparation'] ?? 30} min',
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
                                restaurantInfo['description'] ?? '',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Consumer<ClientDataProvider>(
                    builder: (context, provider, _) {
                      final idB = int.tryParse(idBusiness) ?? 0;
                      final isFav = provider.isFavorite(idB);
                      return GestureDetector(
                        onTap: () {
                          if (idB > 0) provider.toggleFavorite(idB);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isFav ? AppColors.destructive.withOpacity(0.1) : AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppColors.destructive : AppColors.mutedForeground,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
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
          _buildNavItem(Icons.search, 'Rechercher', 1),
          _buildNavItem(Icons.shopping_cart, 'Panier', 2),
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
          case 2:
            targetScreen = const CartScreen();
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
                if (index == 2) // Cart icon with badge
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
}
