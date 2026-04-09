import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/business_data_provider.dart';
import '../business_main_screen.dart';

class BusinessNotificationsView extends StatelessWidget {
  final Function(BusinessScreen) onNavigate;

  const BusinessNotificationsView({super.key, required this.onNavigate});

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessDataProvider>();
    
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forest));
    }

    final notifications = provider.notifications;
    final unreadCount = notifications.where((n) => n['est_lu'] == false).length;

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
                      decoration: const BoxDecoration(color: AppColors.warmWhite, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.arrowLeft, color: AppColors.forest, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Notifications', style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 20)),
                  const Spacer(),
                  if (unreadCount > 0)
                    GestureDetector(
                      onTap: () => provider.markAllAsRead(),
                      child: const Text('Tout marquer lu', style: TextStyle(color: AppColors.forest, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),
            
            Expanded(
              child: notifications.isEmpty
                ? const Center(child: Text('Aucune notification récente.', style: TextStyle(color: AppColors.mutedForeground)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notifDoc = notifications[index];
                      final notifData = notifDoc['notification'] ?? {};
                      
                      final idNot = notifDoc['id_not'].toString();
                      final isUnread = notifDoc['est_lu'] == false;
                      final type = notifData['type'] ?? 'order';
                      final title = notifData['titre'] ?? 'Notification';
                      final message = notifData['message'] ?? '';
                      final time = _formatDate(notifData['created_at'] ?? '');

                      return GestureDetector(
                        onTap: () {
                          if (isUnread) provider.markAsRead(idNot);
                        },
                        child: _buildNotificationItem(
                          title: title,
                          message: message,
                          time: time,
                          type: type,
                          isUnread: isUnread,
                        ),
                      );
                    },
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: isUnread ? AppColors.forest : AppColors.mutedForeground, fontSize: 13, height: 1.4),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 12),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle,)),
          ]
        ],
      ),
    );
  }
}
