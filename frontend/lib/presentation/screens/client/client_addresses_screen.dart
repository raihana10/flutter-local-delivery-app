import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../core/providers/client_data_provider.dart';

class ClientAddressesScreen extends StatefulWidget {
  const ClientAddressesScreen({super.key});

  @override
  State<ClientAddressesScreen> createState() => _ClientAddressesScreenState();
}

class _ClientAddressesScreenState extends State<ClientAddressesScreen> {


  @override
  Widget build(BuildContext context) {
    final clientData = context.watch<ClientDataProvider>();
    final addresses = clientData.addresses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes adresses de livraison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: clientData.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
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

  Widget _buildAddressItem(Map<String, dynamic> addressRelation) {
    // The backend returns user_adresse objects joined with adresse
    final isDefault = addressRelation['is_default'] == true;
    final addressModel = addressRelation['adresse'] ?? {};
    final ville = addressModel['ville'] ?? 'Adresse';
    final idAddress = addressRelation['id_adresse'].toString(); // the linked address
    
    // We don't have titles in the DB model currently, but we could infer by default status
    final title = isDefault ? 'Adresse Principale' : 'Adresse';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? AppColors.accent : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          if (isDefault)
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
            color: isDefault ? AppColors.accent.withOpacity(0.1) : AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDefault ? Icons.home : Icons.location_on,
            color: isDefault ? AppColors.accent : AppColors.mutedForeground,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (isDefault) ...[
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
            ville,
            style: const TextStyle(color: AppColors.mutedForeground, height: 1.4),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.mutedForeground),
          onSelected: (value) async {
            if (value == 'default') {
              final success = await context.read<ClientDataProvider>().updateAddress(idAddress, {'is_default': true});
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse principale mise à jour')));
              }
            } else if (value == 'delete') {
              final success = await context.read<ClientDataProvider>().deleteAddress(idAddress);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse supprimée')));
              }
            }
          },
          itemBuilder: (context) => [
            if (!isDefault)
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
                    if (mounted) {
                      context.read<ClientDataProvider>().addAddress({
                        'ville': 'Tétouan',
                        'latitude': 35.5800,
                        'longitude': -5.3700,
                        'is_default': false,
                        'titre': 'Position actuelle',
                      }).then((success) {
                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse GPS ajoutée')));
                        }
                      });
                    }
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
                onChanged: (val) {
                  // We would bind a controller here for city
                },
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
                onPressed: () async {
                  // Fake manual address data
                  final success = await context.read<ClientDataProvider>().addAddress({
                    'ville': 'Tétouan', // In real life, value from controller
                    'latitude': 35.5800,
                    'longitude': -5.3700,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse ajoutée manuellement')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur ajout d\'adresse')));
                    }
                  }
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
