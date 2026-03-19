import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class StatusToggleButton extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const StatusToggleButton({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color:        isOnline ? AppColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border:       isOnline
              ? null
              : Border.all(color: AppColors.textSecondary.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône cercle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOnline ? AppColors.navyDark : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.navyDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Label
            Text(
              isOnline ? AppStrings.enLigne : AppStrings.horsLigne,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isOnline ? AppColors.navyDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            // Point vert si online
            if (isOnline)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.online,
                ),
              ),
          ],
        ),
      ),
    );
  }
}