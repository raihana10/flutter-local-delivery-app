import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../core/providers/client_data_provider.dart';
import '../../../core/services/location_service.dart';

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
        title: const Text('Mes adresses de livraison',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        label: const Text('Nouvelle adresse',
            style:
                TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined,
              size: 80, color: AppColors.mutedForeground.withOpacity(0.5)),
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
    final idAddress =
        addressRelation['id_adresse'].toString(); // the linked address

    // We don't have titles in the DB model currently, but we could infer by default status
    final title = addressRelation['titre'] ?? (isDefault ? 'Adresse Principale' : 'Adresse');

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
            color: isDefault
                ? AppColors.accent.withOpacity(0.1)
                : AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDefault ? Icons.home : Icons.location_on,
            color: isDefault ? AppColors.accent : AppColors.mutedForeground,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Par défaut',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            addressModel['details'] ?? ville,
            style:
                const TextStyle(color: AppColors.mutedForeground, height: 1.4),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.mutedForeground),
          onSelected: (value) async {
            if (value == 'default') {
              final success = await context
                  .read<ClientDataProvider>()
                  .updateAddress(idAddress, {'is_default': true});
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Adresse principale mise à jour')));
              }
            } else if (value == 'edit') {
              _showEditTitleDialog(idAddress, title);
            } else if (value == 'delete') {
              final success = await context
                  .read<ClientDataProvider>()
                  .deleteAddress(idAddress);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adresse supprimée')));
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'edit', child: Text('Renommer le titre')),
            if (!isDefault)
              const PopupMenuItem(
                  value: 'default', child: Text('Définir par défaut')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer',
                  style: TextStyle(color: AppColors.destructive)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTitleDialog(String addressId, String currentTitle) {
    final titleController = TextEditingController(text: currentTitle);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Renommer le titre', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground)),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'Nouveau titre',
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Annuler', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                final success = await context.read<ClientDataProvider>().updateAddress(addressId, {'titre': newTitle});
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre mis à jour')));
                  Navigator.pop(context);
                }
              }
              titleController.dispose();
            },
            child: const Text('Enregistrer', style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AddAddressBottomSheet();
      },
    );
  }
}

class AddAddressBottomSheet extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic> data)? onSave;

  const AddAddressBottomSheet({super.key, this.onSave});

  @override
  State<AddAddressBottomSheet> createState() => AddAddressBottomSheetState();
}

class AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  final _titleController = TextEditingController();
  final _villeController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationService = LocationService();
  
  double? _latitude;
  double? _longitude;
  bool _isLoadingGps = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _villeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;

        final addressData = await _locationService.getAddressFromCoordinates(_latitude!, _longitude!);
        if (addressData != null && addressData['address'] != null) {
          final address = addressData['address'] ?? {};
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? 'Inconnue';
          final displayName = addressData['display_name'] ?? '';
          
          setState(() {
            _villeController.text = city;
            _addressController.text = displayName;
            if (_titleController.text.isEmpty) {
              _titleController.text = 'Position actuelle';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Position GPS trouvée')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'obtenir la position GPS. Avez-vous autorisé la localisation ?')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la géolocalisation')));
    } finally {
      setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _saveAddress() async {
    if (_villeController.text.isEmpty || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez rechercher une adresse exacte ou utiliser la géolocalisation.')));
      return;
    }

    setState(() => _isSaving = true);
    
    final payload = {
      'titre': _titleController.text.isEmpty ? 'Adresse' : _titleController.text,
      'details': _addressController.text.trim(),
      'ville': _villeController.text,
      'latitude': _latitude,
      'longitude': _longitude,
      'is_default': false,
    };

    bool success;
    if (widget.onSave != null) {
      success = await widget.onSave!(payload);
    } else {
      success = await context.read<ClientDataProvider>().addAddress(payload);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse ajoutée avec succès')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'ajout de l\'adresse')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            onPressed: _isLoadingGps ? null : _getCurrentLocation,
            icon: _isLoadingGps 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: Text(_isLoadingGps ? 'Recherche en cours...' : 'Utiliser ma position actuelle', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 24),
          const Center(child: Text('OU', style: TextStyle(color: AppColors.mutedForeground, fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),

          // Manual Entry Form
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Titre (ex: Maison, Bureau)',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          
          Autocomplete<Map<String, dynamic>>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.length < 3) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              return await _locationService.searchAddress(textEditingValue.text);
            },
            displayStringForOption: (option) => option['display_name'] ?? '',
            onSelected: (Map<String, dynamic> selection) {
              setState(() {
                _latitude = double.tryParse(selection['lat']?.toString() ?? '');
                _longitude = double.tryParse(selection['lon']?.toString() ?? '');
                _addressController.text = selection['display_name'] ?? '';
                
                final address = selection['address'];
                if (address != null) {
                  _villeController.text = address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? '';
                }
              });
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              if (_addressController.text.isNotEmpty && textEditingController.text.isEmpty) {
                 textEditingController.text = _addressController.text;
              }
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  labelText: 'Rechercher une adresse exacte',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.search, color: AppColors.mutedForeground),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 48,
                    color: AppColors.card,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option['display_name'] ?? '', style: const TextStyle(fontSize: 14)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _villeController,
            decoration: InputDecoration(
              labelText: 'Ville',
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
            onPressed: _isSaving ? null : _saveAddress,
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.card, strokeWidth: 2))
                : const Text('Enregistrer l\'adresse', style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
