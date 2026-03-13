import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/client_data_provider.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  State<ClientNotificationsScreen> createState() => _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientDataProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientData = context.watch<ClientDataProvider>();
    final notifications = clientData.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                for (var noti in notifications) {
                  if (noti['est_lu'] == false) {
                    await context.read<ClientDataProvider>().apiService.markNotificationAsRead(noti['id_not'].toString());
                  }
                }
                if (context.mounted) {
                  context.read<ClientDataProvider>().fetchNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Toutes les notifications marquées comme lues')),
                  );
                }
              },
              child: const Text('Tout lire', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: clientData.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<ClientDataProvider>().fetchNotifications();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
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

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    final isRead = item['est_lu'] == true;
    final noti = item['notification'] ?? {};
    
    // Extract data
    final title = noti['titre'] ?? 'Notification';
    final message = noti['message'] ?? '';
    final type = noti['type'] ?? 'info';
    
    // Choose icon and color based on type
    IconData icon = Icons.notifications;
    Color color = AppColors.primary;
    
    switch (type) {
      case 'delivery':
        icon = Icons.delivery_dining;
        color = AppColors.primary;
        break;
      case 'promo':
        icon = Icons.local_offer;
        color = AppColors.accent;
        break;
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'alert':
        icon = Icons.warning;
        color = AppColors.destructive;
        break;
    }

    // Format date string
    String timeString = '';
    if (noti['date'] != null) {
      try {
        final date = DateTime.parse(noti['date']);
        final now = DateTime.now();
        final diff = now.difference(date);
        
        if (diff.inMinutes < 60) {
          timeString = 'Il y a ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          timeString = 'Il y a ${diff.inHours}h';
        } else if (diff.inDays == 1) {
          timeString = 'Hier';
        } else {
          timeString = 'Il y a ${diff.inDays} jours';
        }
      } catch (e) {
        timeString = '';
      }
    }

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          final success = await context.read<ClientDataProvider>().apiService.markNotificationAsRead(item['id_not'].toString());
          if (success && context.mounted) {
            context.read<ClientDataProvider>().fetchNotifications();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? AppColors.card : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
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
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                      if (!isRead)
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
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                  if (timeString.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
