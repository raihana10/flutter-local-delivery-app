import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'restaurant_list_screen.dart';
import 'pharmacy_list_screen.dart';
import 'market_list_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> with TickerProviderStateMixin {
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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _restaurantsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pharmacieController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _supermarcheController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _restaurantsScale = CurvedAnimation(parent: _restaurantsController, curve: Curves.elasticOut);
    _pharmacieScale = CurvedAnimation(parent: _pharmacieController, curve: Curves.elasticOut);
    _supermarcheScale = CurvedAnimation(parent: _supermarcheController, curve: Curves.elasticOut);

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryCircle(
                      'Restaurants', 
                      '🍴', 
                      _restaurantsScale, 
                      AppColors.primary,
                      () => setState(() => _selectedCategory = 'restaurants')
                    ),
                    _buildCategoryCircle(
                      'Pharmacie', 
                      '💊', 
                      _pharmacieScale, 
                      const Color(0xFFE53935),
                      () => setState(() => _selectedCategory = 'pharmacie')
                    ),
                    _buildCategoryCircle(
                      'Supermarché', 
                      '🛒', 
                      _supermarcheScale, 
                      const Color(0xFF43A047),
                      () => setState(() => _selectedCategory = 'supermarche')
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
                child: const Icon(Icons.person_outline, color: AppColors.accent, size: 28),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Tétouan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCircle(String title, String emoji, Animation<double> scale, Color themeColor, VoidCallback onTap) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, title == 'Pharmacie' ? -_floatingAnimation.value : _floatingAnimation.value),
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
}