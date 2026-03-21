import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/data/datasources/super_admin_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../business/business_main_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> users = [];
  String _filterStatus = 'Tous';
  String _filterDate = 'Toutes';

  final _apiService = SuperAdminApiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _apiService.getClients();
      print('CLIENTS RESPONSE: $clients');
      final livreurs = await _apiService.getLivreurs();
      final businesses = await _apiService.getBusinesses();

      if (mounted) {
        setState(() {
          users = [
            ...clients.map((e) => Map<String, dynamic>.from(e)),
            ...livreurs.map((e) => Map<String, dynamic>.from(e)),
            ...businesses.map((e) => Map<String, dynamic>.from(e))
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog(
      int userId, bool currentStatus, String userName) {
    final actionName = currentStatus ? 'Suspendre' : 'Activer';
    final color = currentStatus ? AppColors.destructive : Colors.green;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionName l\'utilisateur ?'),
        content: Text(
            'Êtes-vous sûr de vouloir ${actionName.toLowerCase()} le compte de $userName ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _toggleUserStatus(userId, currentStatus);
            },
            child: Text('Confirmer',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(int userId, bool currentStatus) async {
    final res = await _apiService.toggleUserStatus(userId.toString());
    if (res['success'] == true) {
      setState(() {
        final index = users.indexWhere((u) => u['id_user'] == userId);
        if (index != -1) {
          users[index] = Map<String, dynamic>.from(users[index]);
          users[index]['est_actif'] = !currentStatus;
          if (!currentStatus) {
            users[index]['documents_validation'] =
                'validated'; // schema uses varchar for business/livreur? or we just use truthy visual
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut de l\'utilisateur mis à jour.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${res['error'] ?? 'Inconnue'}')),
        );
      }
    }
  }

// _softDeleteUser removed as per user request

  void _validateDocuments(int userId) async {
    final res = await _apiService.validateUser(userId.toString());
    if (res['success'] == true) {
      setState(() {
        final index = users.indexWhere((u) => u['id_user'] == userId);
        if (index != -1) {
          users[index] = Map<String, dynamic>.from(users[index]);
          // ne pas écraser documents_validation
          users[index]['est_actif'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Documents approuvés et compte activé.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${res['error'] ?? 'Inconnue'}')),
        );
      }
    }
  }

  void _showDocumentValidationModal(Map<String, dynamic> user) {
    String docsValidStr = '';
    
    if (user['role'] == 'livreur' && user['livreur'] != null) {
      final livreurData = (user['livreur'] is List && user['livreur'].isNotEmpty) ? user['livreur'][0] : user['livreur'];
      if (livreurData is Map) docsValidStr = livreurData['documents_validation']?.toString() ?? '';
    } else if (user['role'] == 'business' && user['business'] != null) {
      final businessData = (user['business'] is List && user['business'].isNotEmpty) ? user['business'][0] : user['business'];
      if (businessData is Map) docsValidStr = businessData['documents_validation']?.toString() ?? '';
    } else {
      docsValidStr = user['documents_validation']?.toString() ?? '';
    }

    final urls = docsValidStr.isNotEmpty && docsValidStr != 'validated' && docsValidStr != 'false' 
        ? docsValidStr.split(',') 
        : <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Documents de ${user['nom']}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veuillez vérifier les documents fournis par l\'utilisateur avant de l\'approuver sur la plateforme.'),
              const SizedBox(height: 16),
              if (urls.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aucun document fourni.', style: TextStyle(color: Colors.red)),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: urls.length,
                    itemBuilder: (context, index) {
                      String currentUrl = urls[index].trim();
                      if (!currentUrl.startsWith('http')) {
                        try {
                          currentUrl = Supabase.instance.client.storage.from('alae').getPublicUrl(currentUrl);
                        } catch (e) {
                          // Ignore if supabase is uninitialized
                        }
                      }
                      
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  currentUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.description, size: 48, color: AppColors.accent),
                                          const SizedBox(height: 8),
                                          const Text('Document disponible', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          TextButton.icon(
                                            icon: const Icon(Icons.open_in_new, size: 16),
                                            label: const Text('Ouvrir le document'),
                                            onPressed: () async {
                                              final uri = Uri.parse(currentUrl);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Voir en plein écran'),
                              onPressed: () async {
                                final uri = Uri.parse(currentUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              if (urls.isNotEmpty)
                Text('${urls.length} document(s) trouvé(s)',
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer',
                style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Rejeter'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Documents rejetés. L\'utilisateur sera notifié.')));
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Approuver'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _validateDocuments(user['id_user']);
            },
          ),
        ],
      ),
    );
  }

  void _showUserModal(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Détails de l\'utilisateur',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(LucideIcons.user, 'Nom Complet', user['nom']),
              _buildDetailRow(LucideIcons.mail, 'Email', user['email']),
              _buildDetailRow(LucideIcons.calendar, 'Date d\'inscription',
                  (user['created_at'] as String).substring(0, 10)),
              _buildDetailRow(LucideIcons.tag, 'Rôle',
                  user['role'].toString().toUpperCase()),
              if (user['role'] == 'business')
                _buildDetailRow(LucideIcons.store, 'Type',
                    user['type_business'] ?? 'Non spécifié'),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Fermer'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mutedForeground)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.card,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.accent,
            tabs: const [
              Tab(icon: Icon(LucideIcons.user), text: 'Clients'),
              Tab(icon: Icon(LucideIcons.bike), text: 'Livreurs'),
              Tab(icon: Icon(LucideIcons.store), text: 'Restaurants'),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list,
                      size: 20, color: AppColors.mutedForeground),
                  const SizedBox(width: 8),
                  const Text('Filtres : ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    items: ['Tous', 'Actif', 'Suspendu'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue != null) _filterStatus = newValue;
                      });
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterDate,
                    items: ['Toutes', 'Ce mois-ci'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue != null) _filterDate = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPaginatedTable('client'),
                    _buildPaginatedTable('livreur'),
                    _buildPaginatedTable('business'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPaginatedTable(String role) {
    // ✅ Vérifier que deleted_at est null, pas que la clé est absente
var filteredUsers = users
    .where((u) => u['role'] == role && u['deleted_at'] == null)
    .toList();

    if (_filterStatus != 'Tous') {
      final isActif = _filterStatus == 'Actif';
      filteredUsers =
          filteredUsers.where((u) => u['est_actif'] == isActif).toList();
    }

    if (_filterDate == 'Ce mois-ci') {
      // Implementation logic for date filtering if necessary
    }

    List<DataColumn> columns = [
      const DataColumn(
          label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
      const DataColumn(
          label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
      const DataColumn(
          label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
      const DataColumn(
          label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
    ];

    if (role == 'business') {
      columns.add(const DataColumn(
          label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))));
      columns.add(const DataColumn(
          label: Text('Docs', style: TextStyle(fontWeight: FontWeight.bold))));
    } else if (role == 'livreur') {
      columns.add(const DataColumn(
          label: Text('Docs', style: TextStyle(fontWeight: FontWeight.bold))));
    }

    columns.add(const DataColumn(
        label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))));
    columns.add(const DataColumn(
        label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: PaginatedDataTable(
        header: Text('Liste des $role${role.endsWith('s') ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        rowsPerPage: filteredUsers.length > 5
            ? 5
            : (filteredUsers.isEmpty ? 1 : filteredUsers.length),
        columns: columns,
        source: _UserDataTableSource(
          data: filteredUsers,
          role: role,
          onStatusToggle: _showConfirmationDialog,
          onViewDetails: _showUserModal,
          onValidate: _showDocumentValidationModal,
          onManageBusiness: (user) {
            final biz = user['business'];
            final idBusinessStr = biz is List
                ? (biz.isNotEmpty ? biz[0]['id_business'] : null)
                : (biz != null ? biz['id_business'] : null);
            final idBusiness = int.tryParse(idBusinessStr?.toString() ?? '');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BusinessMainScreen(idBusiness: idBusiness),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final String role;
  final void Function(int, bool, String) onStatusToggle;
  final void Function(Map<String, dynamic>) onViewDetails;
  final void Function(Map<String, dynamic>) onValidate;
  final void Function(Map<String, dynamic>) onManageBusiness;

  _UserDataTableSource({
    required this.data,
    required this.role,
    required this.onStatusToggle,
    required this.onViewDetails,
    required this.onValidate,
    required this.onManageBusiness,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final user = data[index];

    // Read nested livreur/business columns
    bool estActif = true;
    String? docsValidStr;
    
    if (role == 'livreur' && user['livreur'] != null) {
      final livreurData = (user['livreur'] is List && user['livreur'].isNotEmpty) ? user['livreur'][0] : user['livreur'];
      if (livreurData is Map) {
        estActif = livreurData['est_actif'] ?? true;
        docsValidStr = livreurData['documents_validation']?.toString();
      }
    } else if (role == 'business' && user['business'] != null) {
      final businessData = (user['business'] is List && user['business'].isNotEmpty) ? user['business'][0] : user['business'];
      if (businessData is Map) {
        estActif = businessData['est_actif'] ?? true;
        docsValidStr = businessData['documents_validation']?.toString();
      }
    } else {
      estActif = user['est_actif'] ?? true;
      docsValidStr = user['documents_validation']?.toString();
    }

    // Assuming docsValidStr contains URLs if the user uploaded documents
    // It could be either startsWith('http') OR looks like a path e.g., 'livreurs/cni/...',
    // which starts with 'livreurs' or 'businesses' or contains '/'
    final hasDocs = docsValidStr != null && 
        docsValidStr.isNotEmpty && 
        (docsValidStr.startsWith('http') || docsValidStr.contains('/'));
        
    final isPending = !estActif && (role == 'livreur' || role == 'business');

    List<DataCell> cells = [
      DataCell(Text('#${user['id_user']}',
          style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(user['nom'])),
      DataCell(Text(user['email'])),
      DataCell(Text((user['created_at'] as String).substring(0, 10))),
    ];

    if (role == 'business') {
      cells.add(DataCell(Text(user['type_business'] ?? 'N/A')));
      cells.add(
        DataCell(
          Icon(
            hasDocs ? Icons.check_circle : Icons.warning_amber_rounded,
            color: hasDocs ? Colors.green : AppColors.destructive,
            size: 20,
          ),
        ),
      );
    } else if (role == 'livreur') {
      cells.add(
        DataCell(
          Icon(
            hasDocs ? Icons.check_circle : Icons.warning_amber_rounded,
            color: hasDocs ? Colors.green : AppColors.destructive,
            size: 20,
          ),
        ),
      );
    }

    cells.add(
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: estActif
                ? Colors.green.withOpacity(0.1)
                : AppColors.destructive.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            estActif ? 'Actif' : 'Suspendu',
            style: TextStyle(
              color: estActif ? Colors.green : AppColors.destructive,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );

    cells.add(
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.eye,
                  color: AppColors.secondary, size: 20),
              tooltip: 'Voir Profil',
              onPressed: () => onViewDetails(user),
            ),
            if (role == 'business')
              IconButton(
                icon: const Icon(LucideIcons.externalLink,
                    color: AppColors.primary, size: 20),
                tooltip: 'Gérer Business',
                onPressed: () => onManageBusiness(user),
              ),
            if (role == 'livreur' || role == 'business')
              IconButton(
                icon: const Icon(Icons.fact_check,
                    color: AppColors.accent, size: 20),
                tooltip: 'Approuver Documents',
                onPressed: () => onValidate(user),
              ),
            IconButton(
              icon: Icon(estActif ? LucideIcons.ban : LucideIcons.check,
                  color: estActif ? AppColors.destructive : Colors.green,
                  size: 20),
              tooltip: estActif ? 'Suspendre' : 'Activer',
              onPressed: () =>
                  onStatusToggle(user['id_user'], estActif, user['nom']),
            ),
          ],
        ),
      ),
    );

    return DataRow(cells: cells);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
