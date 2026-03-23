import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/data/datasources/super_admin_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRole = 'Tous';
  final _apiService = SuperAdminApiService();

  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifs();
  }

  Future<void> _loadNotifs() async {
    final res = await SuperAdminApiService().getNotifications();
    if (mounted) {
      setState(() {
        notifications = List<Map<String, dynamic>>.from(res);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendNotification() async {
    if (_formKey.currentState!.validate()) {
      try {
        final success = await _apiService.sendNotification({
          'titre': _titleController.text,
          'message': _messageController.text,
          'target_role': _selectedRole,
        });

        if (success) {
          _titleController.clear();
          _messageController.clear();
          // Rafraîchir la liste des notifications
          await _loadNotifs();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notification envoyée avec succès au groupe : $_selectedRole'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'envoi de la notification'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Centre de Notifications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildSendForm()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildHistoryLog()),
                ],
              )
            else
              Column(
                children: [
                  _buildSendForm(),
                  const SizedBox(height: 24),
                  _buildHistoryLog(),
                ],
              )
          ],
        ));
  }

  Widget _buildSendForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Envoyer une nouvelle notification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Cible',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: ['Tous', 'Clients', 'Livreurs', 'Commerce']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedRole = newValue!);
                },
              ),
              const SizedBox(height: 16),
              const Text('Titre',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ex: Nouvelle mise à jour !',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v!.isEmpty ? 'Titre requis' : null,
              ),
              const SizedBox(height: 16),
              const Text('Message',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Votre message ici...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v!.isEmpty ? 'Message requis' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.send),
                label: const Text('Envoyer Notification Push'),
                onPressed: _sendNotification,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryLog() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historique des Envois & Alertes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isAlert =
                    notif['type'] == 'alert' || notif['type'] == 'warning';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isAlert
                        ? AppColors.destructive.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    child: Icon(
                      isAlert
                          ? Icons.warning_amber_rounded
                          : Icons.notifications_none,
                      color: isAlert ? AppColors.destructive : Colors.blue,
                    ),
                  ),
                  title: Text(notif['titre'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notif['message']),
                  trailing: Text(notif['date'],
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.mutedForeground)),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
