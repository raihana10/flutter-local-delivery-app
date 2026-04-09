import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/super_admin_api_service.dart';
import 'business_detail_admin_screen.dart';

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen> {
  final _apiService = SuperAdminApiService();
  bool _isLoading = true;
  List<dynamic> _allBusinesses = [];
  List<dynamic> _filteredBusinesses = [];

  String _selectedType = 'Tous';
  String _selectedStatut = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAdminBusinesses();
      setState(() {
        _allBusinesses = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBusinesses = _allBusinesses.where((b) {
        final type = b['type_business'] ?? '';
        final isActive = b['est_actif'] == true;

        bool typeMatch = _selectedType == 'Tous' ||
            (_selectedType == 'restaurant' && type == 'restaurant') ||
            (_selectedType == 'super-marche' && type == 'super-marche') ||
            (_selectedType == 'pharmacie' && type == 'pharmacie');

        bool statutMatch = _selectedStatut == 'Tous' ||
            (_selectedStatut == 'Actif' && isActive) ||
            (_selectedStatut == 'Inactif' && !isActive);

        return typeMatch && statutMatch;
      }).toList();
    });
  }

  Future<void> _toggleStatus(dynamic business) async {
    try {
      final idUser = business['id_user'].toString();
      final res = await _apiService.toggleUserStatus(idUser);
      if (res['success'] == true || res['message'] != null) {
        _loadBusinesses();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erreur toggle statut')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestion des Businesses',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              isMobile
                  ? Column(
                      children: [
                        _buildDropdown('Type', _selectedType,
                            ['Tous', 'restaurant', 'super-marche', 'pharmacie'], (val) {
                          setState(() => _selectedType = val!);
                          _applyFilters();
                        }),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            'Statut', _selectedStatut, ['Tous', 'Actif', 'Inactif'],
                            (val) {
                          setState(() => _selectedStatut = val!);
                          _applyFilters();
                        }),
                      ],
                    )
                  : Row(
                      children: [
                        _buildDropdown('Type', _selectedType,
                            ['Tous', 'restaurant', 'super-marche', 'pharmacie'], (val) {
                          setState(() => _selectedType = val!);
                          _applyFilters();
                        }),
                        const SizedBox(width: 16),
                        _buildDropdown(
                            'Statut', _selectedStatut, ['Tous', 'Actif', 'Inactif'],
                            (val) {
                          setState(() => _selectedStatut = val!);
                          _applyFilters();
                        }),
                      ],
                    ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadBusinesses,
                        child: ListView.builder(
                          itemCount: _filteredBusinesses.length,
                          itemBuilder: (context, index) {
                            final b = _filteredBusinesses[index];
                            return _buildBusinessCard(b, isMobile);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text(label),
            items: items
                .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item == 'super-marche' ? 'supermarché' : item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(dynamic b, bool isMobile) {
    final bool isActive = b['est_actif'] == true;
    final String type = b['type_business'] ?? 'Inconnu';
    final appUser = b['app_user'] ?? {};
    final nom = appUser['nom'] ?? b['nom_business'] ?? 'Inconnu';
    final email = appUser['email'] ?? '';
    final pendingValidation =
        b['documents_validation'] == null; // Example field
    final idBusiness = b['id_business'];

    IconData icon;
    String typeLabel = type;
    switch (type) {
      case 'restaurant':
        icon = Icons.restaurant;
        typeLabel = 'restaurant 🍽️';
        break;
      case 'super-marche':
        icon = Icons.shopping_cart;
        typeLabel = 'supermarché 🛒';
        break;
      case 'pharmacie':
        icon = Icons.local_pharmacy;
        typeLabel = 'pharmacie 💊';
        break;
      default:
        icon = Icons.store;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(icon, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nom,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(color: AppColors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(typeLabel, Colors.blue),
                      _buildBadge(
                        isActive ? 'Actif 🟢' : 'Inactif 🔴',
                        isActive ? Colors.green : Colors.red,
                      ),
                      if (pendingValidation)
                        _buildBadge('En attente validation', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _toggleStatus(b),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isActive ? Colors.red : Colors.green,
                            side: BorderSide(
                              color: isActive ? Colors.red : Colors.green,
                            ),
                          ),
                          child: Text(isActive ? 'Suspendre' : 'Activer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusinessDetailAdminScreen(
                                  idBusiness: idBusiness,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Gérer →',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(icon, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nom,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email,
                            style: const TextStyle(color: AppColors.mutedForeground)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadge(typeLabel, Colors.blue),
                            _buildBadge(isActive ? 'Actif 🟢' : 'Inactif 🔴',
                                isActive ? Colors.green : Colors.red),
                            if (pendingValidation)
                              _buildBadge('En attente validation', Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () => _toggleStatus(b),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: isActive ? Colors.red : Colors.green,
                              side: BorderSide(
                                  color: isActive ? Colors.red : Colors.green)),
                          child: Text(isActive ? 'Suspendre' : 'Activer'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BusinessDetailAdminScreen(
                                      idBusiness: idBusiness)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary),
                          child: const Text('Gérer →',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
