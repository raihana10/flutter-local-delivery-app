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
  
  final Map<String, String> _labels = {
    'prix_par_km': 'Frais de livraison par Km (MAD)',
    'commission_business_rate': 'Commission App sur Business',
    'business_rate': 'Revenus Business',
    'livreur_rate': 'Revenus Livreur',
    'app_livraison_rate': 'Commission App sur Livraison',
  };

  final Map<String, String> _descriptions = {
    'prix_par_km': 'Prix facturé par kilomètre pour la livraison',
    'commission_business_rate': 'Pourcentage prélevé sur les ventes des commerces',
    'business_rate': 'Part des revenus reversée aux commerces',
    'livreur_rate': 'Part des frais de livraison reversée aux livreurs',
    'app_livraison_rate': 'Commission sur les frais de livraison',
  };

  final Map<String, IconData> _icons = {
    'prix_par_km': LucideIcons.mapPin,
    'commission_business_rate': LucideIcons.percent,
    'business_rate': LucideIcons.store,
    'livreur_rate': LucideIcons.truck,
    'app_livraison_rate': LucideIcons.building,
  };

  final Map<String, Color> _colors = {
    'prix_par_km': Colors.blue,
    'commission_business_rate': Colors.purple,
    'business_rate': Colors.green,
    'livreur_rate': Colors.orange,
    'app_livraison_rate': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    try {
      final configs = await _apiService.getConfigs();
      if (mounted) {
        setState(() {
          _configs = configs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateConfig(String key, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 12),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 400,
            ),
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_colors[key] ?? AppColors.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _icons[key] ?? LucideIcons.settings,
                        color: _colors[key] ?? AppColors.primary,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _labels[key] ?? key,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_descriptions[key] != null && !isMobile) ...[
                            const SizedBox(height: 4),
                            Text(
                              _descriptions[key]!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_descriptions[key] != null && isMobile) ...[
                  const SizedBox(height: 8),
                  Text(
                    _descriptions[key]!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Valeur actuelle : $currentValue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Nouvelle valeur',
                    hintText: 'Ex: 0.25',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(
                      key.contains('rate') || key.contains('prix') 
                          ? LucideIcons.percent 
                          : LucideIcons.hash,
                      size: 18,
                    ),
                  ),
                  autofocus: true,
                  onSubmitted: (_) => Navigator.pop(context, true),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isMobile ? 44 : 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: isMobile ? 44 : 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Enregistrer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldSave == true && controller.text.trim().isNotEmpty) {
      final newValue = controller.text.trim();
      setState(() => _isLoading = true);
      
      try {
        final success = await _apiService.updateConfig(key, newValue);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_labels[key] ?? key} mis à jour avec succès!',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
          await _loadConfigs();
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Erreur lors de la mise à jour')),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
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

  String _getValueLabel(String key, String value) {
    if (key.contains('rate')) {
      final percent = (double.tryParse(value) ?? 0) * 100;
      return '${percent.toStringAsFixed(1)}%';
    } else if (key == 'prix_par_km') {
      return '$value MAD';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                _buildMobileHeader()
              else
                _buildDesktopHeader(isTablet: isTablet),
              
              SizedBox(height: isMobile ? 16 : 24),
              
              if (isMobile)
                _buildMobileSettingsList()
              else
                _buildDesktopSettingsList(isTablet: isTablet),
              
              if (!isMobile) ...[
                const SizedBox(height: 24),
                _buildInfoCard(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.settings,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadConfigs,
              icon: const Icon(LucideIcons.refreshCw, size: 20),
              tooltip: 'Rafraîchir',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withOpacity(0.1),
              ),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configuration des commissions et tarifs',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader({required bool isTablet}) {
    final iconSize = isTablet ? 24.0 : 28.0;
    final titleSize = isTablet ? 22.0 : 24.0;
    final subtitleSize = isTablet ? 13.0 : 14.0;
    final buttonIconSize = isTablet ? 16.0 : 18.0;
    final buttonTextSize = isTablet ? 13.0 : 14.0;
    final buttonPaddingH = isTablet ? 16.0 : 20.0;
    final buttonPaddingV = isTablet ? 12.0 : 16.0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.settings,
            size: iconSize,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Paramètres de l\'Application',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gérez les commissions, tarifs et configurations globales',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _loadConfigs,
          icon: Icon(LucideIcons.refreshCw, size: buttonIconSize),
          label: Text(
            'Rafraîchir',
            style: TextStyle(fontSize: buttonTextSize),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: buttonPaddingH,
              vertical: buttonPaddingV,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSettingsList() {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _configs.length,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final key = _configs.keys.elementAt(index);
      final value = _configs[key]!;
      final label = _labels[key] ?? key;
      final color = _colors[key] ?? AppColors.primary;
      final icon = _icons[key] ?? LucideIcons.settings;
      
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              if (_descriptions[key] != null) ...[
                const SizedBox(height: 8),
                Text(
                  _descriptions[key]!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Valeur actuelle',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _getValueLabel(key, value),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Correction : Supprimer SizedBox et utiliser directement ElevatedButton
                  ElevatedButton(
                    onPressed: () => _updateConfig(key, value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // Ajouter une hauteur fixe via tapTargetSize ou minimumSize
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Modifier',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildDesktopSettingsList({required bool isTablet}) {
    final paddingH = isTablet ? 16.0 : 24.0;
    final paddingV = isTablet ? 8.0 : 12.0;
    final iconSize = isTablet ? 20.0 : 24.0;
    final titleSize = isTablet ? 14.0 : 15.0;
    final descSize = isTablet ? 11.0 : 12.0;
    final valuePaddingH = isTablet ? 12.0 : 16.0;
    final valuePaddingV = isTablet ? 6.0 : 8.0;
    final valueSize = isTablet ? 14.0 : 16.0;
    final editIconSize = isTablet ? 20.0 : 22.0;
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _configs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final key = _configs.keys.elementAt(index);
          final value = _configs[key]!;
          final label = _labels[key] ?? key;
          final color = _colors[key] ?? AppColors.primary;
          final icon = _icons[key] ?? LucideIcons.settings;
          
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: color,
                  ),
                ),
                SizedBox(width: isTablet ? 12.0 : 16.0),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleSize,
                        ),
                      ),
                      if (_descriptions[key] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _descriptions[key]!,
                          style: TextStyle(
                            fontSize: descSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: isTablet ? 8.0 : 16.0),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: valuePaddingH,
                    vertical: valuePaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getValueLabel(key, value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: valueSize,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 8.0 : 16.0),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: AppColors.accent,
                    size: editIconSize,
                  ),
                  onPressed: () => _updateConfig(key, value),
                  tooltip: 'Modifier ${_labels[key] ?? key}',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Les modifications sont appliquées immédiatement et affecteront les nouvelles commandes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
