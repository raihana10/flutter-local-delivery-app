import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../business_main_screen.dart';

class BusinessNotificationsView extends StatelessWidget {
  final Function(BusinessScreen) onNavigate;

  const BusinessNotificationsView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onNavigate(BusinessScreen.dashboard),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          color: AppColors.warmWhite, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.arrowLeft,
                          color: AppColors.forest, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Notifications',
                      style: TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('Tout marquer lu',
                        style: TextStyle(
                            color: AppColors.forest,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  const Text('Aujourd\'hui',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.mutedForeground)),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    title: 'Nouvelle commande #1045',
                    message: 'Mohamed A. a commandé 3 plats. Préparez-la !',
                    time: 'Il y a 2 min',
                    type: 'order',
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    title: 'Commande #1042 livrée',
                    message:
                        'La commande pour Alae B. a été livrée avec succès.',
                    time: 'Il y a 45 min',
                    type: 'success',
                    isUnread: true,
                  ),
                  const SizedBox(height: 24),
                  const Text('Hier',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.mutedForeground)),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    title: 'Message du support',
                    message:
                        'Votre document de validation a été accepté. Votre profil est maintenant public.',
                    time: 'Hier, 14:30',
                    type: 'support',
                    isUnread: false,
                  ),
                  _buildNotificationItem(
                    title: 'Nouvelle note !',
                    message:
                        'Un client vous a attribué 5 étoiles pour sa commande passée ce matin.',
                    time: 'Hier, 10:15',
                    type: 'rating',
                    isUnread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required String type,
    required bool isUnread,
  }) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (type) {
      case 'order':
        icon = LucideIcons.shoppingBag;
        iconColor = AppColors.amber;
        iconBg = AppColors.amber.withOpacity(0.2);
        break;
      case 'success':
        icon = LucideIcons.check;
        iconColor = AppColors.sage;
        iconBg = AppColors.sage.withOpacity(0.2);
        break;
      case 'support':
        icon = LucideIcons.messageCircle;
        iconColor = Colors.blue;
        iconBg = Colors.blue.withOpacity(0.2);
        break;
      case 'rating':
        icon = LucideIcons.star;
        iconColor = AppColors.gold;
        iconBg = AppColors.gold.withOpacity(0.2);
        break;
      default:
        icon = LucideIcons.bell;
        iconColor = AppColors.forest;
        iconBg = AppColors.warmWhite;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUnread ? AppColors.cardShadow : [],
        border: !isUnread ? Border.all(color: Colors.black12) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                            fontSize: 14)),
                    Text(time,
                        style: const TextStyle(
                            color: AppColors.mutedForeground, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message,
                    style: TextStyle(
                        color: isUnread
                            ? AppColors.forest
                            : AppColors.mutedForeground,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 12),
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                )),
          ]
        ],
      ),
    );
  }
}
