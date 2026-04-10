import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/super_admin_api_service.dart';

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
        // Step 1: Create notification in notification table
        final notif = await Supabase.instance.client
            .from('notification')
            .insert({
              'titre': _titleController.text,
              'message': _messageController.text,
              'type': _selectedRole,
              'date': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        print('✅ Notification créée: ID=${notif['id_not']}');

        // Step 2: Link to users via user_notification
        var query = Supabase.instance.client.from('app_user').select('id_user');
        
        if (_selectedRole == 'Clients') {
          query = query.eq('role', 'client');
        } else if (_selectedRole == 'Livreurs') {
          query = query.eq('role', 'livreur');
        } else if (_selectedRole == 'Commerce') {
          query = query.eq('role', 'business');
        }
        
        final targetUsers = await query;
        print('👥 Utilisateurs ciblés: ${targetUsers.length}');
        
        if (targetUsers.isNotEmpty) {
          final insertData = targetUsers.map((u) => <String, dynamic>{
            'id_user': u['id_user'],
            'id_not': notif['id_not'],
            'est_lu': false,
          }).toList();
          
          print('💾 Insertion de ${insertData.length} liens user_notification');
          try {
            await Supabase.instance.client.from('user_notification').insert(insertData);
            print('✅ Insertion multiple réussie');
          } catch (e) {
            print('❌ Erreur insertion multiple: $e');
            // Réessayer une par une
            for (final data in insertData) {
              try {
                await Supabase.instance.client.from('user_notification').insert(data);
              } catch (e2) {
                print('❌ Erreur insertion individuelle pour user ${data['id_user']}: $e2');
              }
            }
          }
        } else {
          print('⚠️ Aucun utilisateur trouvé pour le type: $_selectedRole');
        }

        _titleController.clear();
        _messageController.clear();
        await _loadNotifs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification envoyée avec succès au groupe : $_selectedRole (${targetUsers.length} utilisateurs)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Erreur envoi notification: $e');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    final isTablet = screenWidth >= 600 && screenWidth < 800;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth < 600 ? 16.0 : 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centre de Notifications',
                  style: TextStyle(
                    fontSize: screenWidth < 600 ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenWidth < 600 ? 16 : 24),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _buildSendForm(isDesktop: true)),
                      SizedBox(width: screenWidth < 600 ? 16 : 24),
                      Expanded(flex: 2, child: _buildHistoryLog()),
                    ],
                  )
                else if (isTablet)
                  Column(
                    children: [
                      _buildSendForm(isDesktop: false),
                      SizedBox(height: 24),
                      _buildHistoryLog(),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildSendForm(isDesktop: false),
                      SizedBox(height: 16),
                      _buildHistoryLog(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendForm({required bool isDesktop}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Envoyer une nouvelle notification',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isDesktop ? 24 : 16),
              Text(
                'Cible',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 12,
                    vertical: isDesktop ? 12 : 10,
                  ),
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
              SizedBox(height: isDesktop ? 16 : 12),
              Text(
                'Titre',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ex: Nouvelle mise à jour !',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 12,
                    vertical: isDesktop ? 12 : 10,
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Titre requis' : null,
              ),
              SizedBox(height: isDesktop ? 16 : 12),
              Text(
                'Message',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: isDesktop ? 4 : 3,
                decoration: InputDecoration(
                  hintText: 'Votre message ici...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 12,
                    vertical: isDesktop ? 12 : 10,
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Message requis' : null,
              ),
              SizedBox(height: isDesktop ? 24 : 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    LucideIcons.send,
                    size: isDesktop ? 24 : 20,
                  ),
                  label: Text(
                    'Envoyer Notification Push',
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                  onPressed: _sendNotification,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 16 : 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildHistoryLog() {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 600;

  return Card(
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des Envois & Alertes',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          if (notifications.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 20 : 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: isSmallScreen ? 48 : 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune notification',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isAlert = notif['type'] == 'alert' || notif['type'] == 'warning';
                
                // Formater la date pour qu'elle soit plus courte
                final dateString = _formatDate(notif['date']);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône
                      CircleAvatar(
                        radius: isSmallScreen ? 20 : 24,
                        backgroundColor: isAlert
                            ? AppColors.destructive.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        child: Icon(
                          isAlert
                              ? Icons.warning_amber_rounded
                              : Icons.notifications_none,
                          size: isSmallScreen ? 20 : 24,
                          color: isAlert ? AppColors.destructive : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Contenu texte
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre et date sur la même ligne
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['titre'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateString,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Message sur plusieurs lignes
                            Text(
                              notif['message'],
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: isSmallScreen ? 3 : 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Info supplémentaire : type de notification
                            if (isSmallScreen)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAlert
                                        ? AppColors.destructive.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    notif['type'] ?? 'info',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isAlert
                                          ? AppColors.destructive
                                          : Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}

// Fonction pour formater la date de façon plus courte
String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365} an${difference.inDays ~/ 365 > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} mois';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'À l\'instant';
    }
  } catch (e) {
    // Si le parsing échoue, retourner la date brute ou la tronquer
    if (dateString.length > 10) {
      return dateString.substring(0, 10);
    }
    return dateString;
  }
} }