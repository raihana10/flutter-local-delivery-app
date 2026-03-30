import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/super_admin_api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final SuperAdminApiService _apiService = SuperAdminApiService();
  
  bool _isLoading = true;
  Map<String, String> _configs = {};
  
  // Noms d'affichage pour les configurations
  final Map<String, String> _labels = {
    'prix_par_km': 'Frais de livraison par Km (MAD)',
    'commission_business_rate': 'Commission Application sur Business (Taux ex: 0.25)',
    'business_rate': 'Revenus Business (Taux ex: 0.75)',
    'livreur_rate': 'Revenus Livreur (Frais liv. ex: 0.85)',
    'app_livraison_rate': 'Commission Application sur Livraison (Taux ex: 0.15)',
  };

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    final configs = await _apiService.getConfigs();
    setState(() {
      _configs = configs;
      _isLoading = false;
    });
  }

  Future<void> _updateConfig(String key, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier ${_labels[key] ?? key}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Valeur numérique',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(0, 48), // override infinite width theme
              ),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldSave == true && controller.text.trim().isNotEmpty) {
      final newValue = controller.text.trim();
      setState(() => _isLoading = true);
      
      final success = await _apiService.updateConfig(key, newValue);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration mise à jour avec succès!')),
          );
        }
        await _loadConfigs();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la mise à jour.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.settings, size: 28, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text(
                'Paramètres de l\'Application',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadConfigs,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Rafraîchir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48), // override infinite width theme
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: Colors.black12,
              child: ListView.separated(
                itemCount: _configs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final key = _configs.keys.elementAt(index);
                  final value = _configs[key]!;
                  final label = _labels[key] ?? key;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Clé technique : $key', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.accent),
                          onPressed: () => _updateConfig(key, value),
                          tooltip: 'Modifier',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
