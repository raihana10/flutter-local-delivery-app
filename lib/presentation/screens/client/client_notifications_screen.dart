import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ClientNotificationsScreen extends StatelessWidget {
  const ClientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications data for now
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Commande en cours de livraison',
        'message': 'Votre livreur Amine est en route. Suivez votre commande !',
        'time': 'Il y a 5 min',
        'isRead': false,
        'icon': Icons.delivery_dining,
        'color': AppColors.primary,
      },
      {
        'title': 'Promo du week-end 🎉',
        'message': '-20% sur tous les burgers avec le code BURGER20.',
        'time': 'Il y a 2h',
        'isRead': true,
        'icon': Icons.local_offer,
        'color': AppColors.accent,
      },
      {
        'title': 'Commande livrée',
        'message': 'Votre commande #1042 a été livrée. Bon appétit !',
        'time': 'Hier',
        'isRead': true,
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Action to mark all as read
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toutes les notifications marquées comme lues')),
              );
            },
            child: const Text('Tout lire', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.mutedForeground.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous n\'avez pas encore reçu de notifications.',
            style: TextStyle(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['isRead'] ? AppColors.card : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification['isRead'] ? AppColors.border : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notification['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(notification['icon'], color: notification['color'], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification['isRead'] ? FontWeight.w600 : FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    if (!notification['isRead'])
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification['message'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
