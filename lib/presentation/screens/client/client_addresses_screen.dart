import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ClientAddressesScreen extends StatefulWidget {
  const ClientAddressesScreen({super.key});

  @override
  State<ClientAddressesScreen> createState() => _ClientAddressesScreenState();
}

class _ClientAddressesScreenState extends State<ClientAddressesScreen> {
  // Mock data for addresses
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': 1,
      'title': 'Domicile',
      'subtitle': 'Avenue Hassan II, Résidence Al Boustane, Appt 12, Tétouan',
      'is_default': true,
      'latitude': 35.5889,
      'longitude': -5.3626,
    },
    {
      'id': 2,
      'title': 'Travail',
      'subtitle': 'Quartier Administratif, Près de la Wilaya, Tétouan',
      'is_default': false,
      'latitude': 35.5721,
      'longitude': -5.3712,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes adresses de livraison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return _buildAddressItem(address);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressBottomSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt, color: AppColors.card),
        label: const Text('Nouvelle adresse', style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: AppColors.mutedForeground.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucune adresse',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous n\'avez pas encore ajouté d\'adresse de livraison.',
            style: TextStyle(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(Map<String, dynamic> address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address['is_default'] ? AppColors.accent : AppColors.border,
          width: address['is_default'] ? 2 : 1,
        ),
        boxShadow: [
          if (address['is_default'])
            BoxShadow(
              color: AppColors.accent.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: address['is_default'] ? AppColors.accent.withOpacity(0.1) : AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            address['title'] == 'Domicile' ? Icons.home : (address['title'] == 'Travail' ? Icons.work : Icons.location_on),
            color: address['is_default'] ? AppColors.accent : AppColors.mutedForeground,
          ),
        ),
        title: Row(
          children: [
            Text(
              address['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (address['is_default']) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Par défaut', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            address['subtitle'],
            style: const TextStyle(color: AppColors.mutedForeground, height: 1.4),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.mutedForeground),
          onSelected: (value) {
            if (value == 'default') {
              setState(() {
                for (var a in _addresses) {
                  a['is_default'] = a['id'] == address['id'];
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse principale mise à jour')));
            } else if (value == 'delete') {
              setState(() {
                _addresses.removeWhere((a) => a['id'] == address['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse supprimée')));
            }
          },
          itemBuilder: (context) => [
            if (!address['is_default'])
              const PopupMenuItem(value: 'default', child: Text('Définir par défaut')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer', style: TextStyle(color: AppColors.destructive)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ajouter une adresse',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Geolocation Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recherche de votre position GPS en cours...')),
                  );
                  // Simulate fetching geolocation and adding
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      _addresses.add({
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'title': 'Position actuelle',
                        'subtitle': 'Rue détectée par GPS, Tétouan',
                        'is_default': false,
                        'latitude': 35.5800,
                        'longitude': -5.3700,
                      });
                    });
                  });
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Utiliser ma position actuelle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 24),
              const Center(child: Text('OU', style: TextStyle(color: AppColors.mutedForeground, fontWeight: FontWeight.bold))),
              const SizedBox(height: 24),

              // Manual Entry Form
              TextField(
                decoration: InputDecoration(
                  labelText: 'Titre (ex: Maison, Bureau)',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Ville',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Adresse complète',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse ajoutée manuellement')));
                },
                child: const Text('Enregistrer l\'adresse', style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
