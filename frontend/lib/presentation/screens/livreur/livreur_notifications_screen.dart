import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/providers/livreur_dashboard_provider.dart';

class LivreurNotificationsScreen extends StatelessWidget {
  const LivreurNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Notifications', style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<LivreurDashboardProvider>().fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
          }
          final notifs = snapshot.data ?? [];
          if (notifs.isEmpty) {
            return const Center(
              child: Text(
                'Aucune nouvelle notification pour le moment',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = notifs[index];
              final dt = n['created_at'] != null ? DateTime.tryParse(n['created_at'].toString())?.toLocal() : null;
              final dateStr = dt != null ? "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} à ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}" : '';
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(Icons.check_circle_outline, color: AppColors.forest, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(n['titre'] ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyDark)),
                              ),
                              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(n['message'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
