import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/client_data_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'restaurant_detail_screen.dart';
import 'cart_screen.dart';
import 'client_profile_screen.dart';
import 'client_notifications_screen.dart';
import 'restaurant_list_screen.dart';
import 'pharmacy_list_screen.dart';
import 'market_list_screen.dart';
import 'client_addresses_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _selectedCategory;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Animation for each circle
  late AnimationController _restaurantsController;
  late AnimationController _pharmacieController;
  late AnimationController _supermarcheController;

  late Animation<double> _restaurantsScale;
  late Animation<double> _pharmacieScale;
  late Animation<double> _supermarcheScale;

  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Fetch real data once after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClientDataProvider>().fetchHomeData();
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _restaurantsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pharmacieController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _supermarcheController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _restaurantsScale = CurvedAnimation(
        parent: _restaurantsController, curve: Curves.elasticOut);
    _pharmacieScale =
        CurvedAnimation(parent: _pharmacieController, curve: Curves.elasticOut);
    _supermarcheScale = CurvedAnimation(
        parent: _supermarcheController, curve: Curves.elasticOut);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Staggered animation for circles
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _restaurantsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pharmacieController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _supermarcheController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _restaurantsController.dispose();
    _pharmacieController.dispose();
    _supermarcheController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory == 'restaurants') {
      return WillPopScope(
        onWillPop: () async {
          setState(() => _selectedCategory = null);
          return false;
        },
        child: const RestaurantListScreen(),
      );
    } else if (_selectedCategory == 'pharmacie') {
      return WillPopScope(
        onWillPop: () async {
          setState(() => _selectedCategory = null);
          return false;
        },
        child: const PharmacyListScreen(),
      );
    } else if (_selectedCategory == 'supermarche') {
      return WillPopScope(
        onWillPop: () async {
          setState(() => _selectedCategory = null);
          return false;
        },
        child: const MarketListScreen(),
      );
    }

    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildHeader(user?.nom),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Text(
                        'Bienvenue chez',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LivrApp',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withOpacity(0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Que souhaitez-vous commander aujourd\'hui ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryCircle(
                        'Restaurants',
                        '🍴',
                        _restaurantsScale,
                        AppColors.primary,
                        () =>
                            setState(() => _selectedCategory = 'restaurants')),
                    _buildCategoryCircle(
                        'Pharmacie',
                        '💊',
                        _pharmacieScale,
                        const Color(0xFFE53935),
                        () => setState(() => _selectedCategory = 'pharmacie')),
                    _buildCategoryCircle(
                        'Courses',
                        '🛒',
                        _supermarcheScale,
                        const Color(0xFF43A047),
                        () =>
                            setState(() => _selectedCategory = 'supermarche')),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_outline,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour,',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    name ?? 'Client',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientNotificationsScreen(),
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
                          final hasUnread =
                              data.notifications.any((n) => n['lu'] == false);
                          if (!hasUnread) return const SizedBox.shrink();

                          return Positioned(
                            top: 12,
                            right: 12,
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
              // 3-dot menu for Profile and Logout
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.card,
                elevation: 8,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                        SizedBox(width: 12),
                        Text('Mon Profil', style: TextStyle(color: AppColors.foreground)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.destructive, size: 20),
                        SizedBox(width: 12),
                        Text('Déconnexion', style: TextStyle(color: AppColors.destructive)),
                      ],
                    ),
                  ),
                ],
                onSelected: (String value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientProfileScreen(),
                      ),
                    );
                  } else if (value == 'logout') {
                    context.read<AuthProvider>().logout();
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.more_vert, color: AppColors.foreground, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCircle(String title, String emoji,
      Animation<double> scale, Color themeColor, VoidCallback onTap) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                  0,
                  title == 'Pharmacie'
                      ? -_floatingAnimation.value
                      : _floatingAnimation.value),
              child: child,
            );
          },
          child: ScaleTransition(
            scale: scale,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeColor.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                    ),
                    // Inner circle with emoji
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
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

  Widget _buildCategoryChip(String label, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.card,
              borderRadius: BorderRadius.circular(20),
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
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.mutedForeground,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
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
        'emoji': '🍕'
      },
      {
        'title': 'Burger -20%',
        'subtitle': 'Burger House',
        'color': AppColors.accent,
        'emoji': '🍔'
      },
      {
        'title': 'Sushi -30%',
        'subtitle': 'Sushi Bar',
        'color': AppColors.primary,
        'emoji': '🍱'
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
                          Text(
                            promo['emoji'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
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

  Widget _buildRestaurantCard(int index, ClientDataProvider data) {
    if (data.restaurants.isEmpty) return const SizedBox.shrink();

    final restaurantInfo = data.restaurants[index % data.restaurants.length];
    final user = restaurantInfo['app_user'] ?? {};

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
                  restaurantName: user['nom'] ?? 'Restaurant',
                  heroTag: 'restaurant_${restaurantInfo['id_business']}_$index',
                  businessId: restaurantInfo['id_business']?.toString() ?? '0',
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
                  Hero(
                    tag: 'restaurant_${restaurantInfo['id_business']}_$index',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                                user['nom'] ?? 'Restaurant',
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
                        Row(
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
                                  Icon(
                                    Icons.star,
                                    color: AppColors.accent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '4.5', // mock rating for now until aggregate review added
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                  Icon(
                                    Icons.access_time,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${restaurantInfo['temps_preparation'] ?? 30} min',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                  Icon(
                                    Icons.location_on,
                                    color: AppColors.secondary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '1.2 km', // Mock distance until geolocation added
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Livraison gratuite',
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
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.mutedForeground.withOpacity(0.6),
                    size: 16,
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
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // Navigation logic for other tabs
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
            // Reset to home tab when returning
            setState(() {
              _currentIndex = 0;
            });
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
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Consumer<ClientDataProvider>(
                          builder: (context, data, child) {
                            return Text(
                              '${data.cartItems.length}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
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
