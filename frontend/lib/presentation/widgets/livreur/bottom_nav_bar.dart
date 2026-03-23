import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class LivreurBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LivreurBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pdpUrl = context.watch<AuthProvider>().user?.pdp;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home_rounded,
                  label: AppStrings.navAccueil,
                  onTap: onTap),
              _NavItem(
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.near_me_rounded,
                  label: AppStrings.navLivraison,
                  onTap: onTap),
              _NavItem(
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  onTap: onTap),
              _NavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  onTap: onTap),
              _NavItem(
                  index: 4,
                  currentIndex: currentIndex,
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  imageUrl: pdpUrl,
                  onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;
  final String? imageUrl;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.yellow : Colors.transparent, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Icon(
                icon,
                color: selected ? AppColors.yellow : AppColors.textSecondary,
                size: 24,
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.yellow : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // Point indicateur
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.yellow : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
