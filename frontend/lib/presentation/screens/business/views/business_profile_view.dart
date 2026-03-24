import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/business_data_provider.dart';
import '../../client/client_addresses_screen.dart';
import '../business_main_screen.dart';

class BusinessProfileView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;

  const BusinessProfileView({super.key, required this.onNavigate});

  @override
  State<BusinessProfileView> createState() => _BusinessProfileViewState();
}

class _BusinessProfileViewState extends State<BusinessProfileView> {
  bool _isSwitching = false;
  bool _isUploadingPhoto = false;

  Future<void> _pickAndUploadPhoto(BusinessDataProvider provider) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      // Use picked.name to get the proper file name/extension (avoids blob:// path on web)
      final name = picked.name;
      final dotIdx = name.lastIndexOf('.');
      final ext = dotIdx >= 0 ? name.substring(dotIdx + 1).toLowerCase() : 'jpg';
      final mimeMap = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'webp': 'image/webp', 'gif': 'image/gif'};
      final mimeType = mimeMap[ext] ?? 'image/jpeg';
      final businessId = provider.profile['id_user']?.toString() ?? 'unknown';
      final fileName = 'logo_${businessId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('alae')
          .uploadBinary(fileName, bytes, fileOptions: FileOptions(upsert: true, contentType: mimeType));

      final publicUrl = Supabase.instance.client.storage
          .from('alae')
          .getPublicUrl(fileName);

      await provider.updateProfile({'pdp': publicUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour avec succès')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessDataProvider>();

    if (provider.isLoading || provider.profile.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forest));
    }

    final profile = provider.profile;
    final appUser = profile['app_user'] ?? {};
    final nom = appUser['nom']?.toString() ?? 'Nom du Restaurant';
    final description = profile['description']?.toString() ?? 'Restaurant';
    final typeBusiness = profile['type']?.toString() ?? 'Restaurant';
    final isOpen = profile['is_open'] == true;
    final horairesRaw = profile['opening_hours'];
    final timePrep = profile['temps_preparation']?.toString() ?? '15';
    final logoUrl = profile['pdp']?.toString() ?? 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop';
    final coverUrl = profile['cover_url']?.toString() ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&h=300&fit=crop';

    // Build address display string
    final userAddresses = (appUser['user_adresse'] as List<dynamic>? ?? []);
    String addressDisplay = 'Non définie';
    if (userAddresses.isNotEmpty) {
      final primary = userAddresses.firstWhere(
        (ua) => ua['is_default'] == true,
        orElse: () => userAddresses.first,
      );
      final adr = primary['adresse'] ?? {};
      addressDisplay = adr['details']?.toString().isNotEmpty == true
          ? adr['details']
          : adr['ville'] ?? 'Non définie';
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => widget.onNavigate(BusinessScreen.dashboard),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.warmWhite, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.arrowLeft, color: AppColors.forest, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Profil Business', style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),

              // Business Logo (tappable for upload) - only keep profile photo
              Center(
                child: GestureDetector(
                  onTap: () => _pickAndUploadPhoto(provider),
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.warmWhite,
                          backgroundImage: NetworkImage(logoUrl),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.forest, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.forest)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Open Status Toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.sage.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isOpen ? AppColors.sage.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: isOpen ? AppColors.sage : Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(isOpen ? 'Aujourd\'hui: Ouvert' : 'Actuellement Fermé',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isOpen ? AppColors.sage : Colors.red)),
                      ],
                    ),
                    Switch(
                      value: isOpen,
                      onChanged: _isSwitching ? null : (v) async {
                        setState(() => _isSwitching = true);
                        final success = await provider.updateProfile({'is_open': v});
                        setState(() => _isSwitching = false);
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour.')));
                        }
                      },
                      activeColor: AppColors.sage,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text('Informations Générales', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 16)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showEditModal(context, description, timePrep, horairesRaw, provider),
                      child: const Icon(LucideIcons.pencil, color: AppColors.forest, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildActionTile(LucideIcons.store, 'Type de Business', typeBusiness, onTap: () {}),
                    _buildActionTile(LucideIcons.clock, 'Horaires d\'ouverture', _formatHoraires(horairesRaw), onTap: () {}),
                    _buildActionTile(LucideIcons.timer, 'Temps de préparation moyen', '$timePrep mins', onTap: () {}),
                    _buildActionTile(LucideIcons.mapPin, 'Adresse', addressDisplay, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessAddressesScreen(provider: provider),
                        ),
                      ).then((_) => provider.fetchProfile());
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Comptes & Sécurité', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildActionTile(LucideIcons.fileText, 'Documents de validation', 'Validés', isSuccess: true, onTap: () {}),
                    _buildActionTile(LucideIcons.logOut, 'Déconnexion', '', isDestructive: true, onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isSwitching || _isUploadingPhoto)
          Container(
            color: Colors.white54,
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.forest),
                if (_isUploadingPhoto) ...[
                  const SizedBox(height: 12),
                  const Text('Upload en cours...', style: TextStyle(color: AppColors.forest)),
                ]
              ],
            )),
          ),
      ],
    );
  }

  String _formatHoraires(dynamic raw) {
    if (raw == null) return 'Non défini';
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is Map) {
        final mode = decoded['mode'];
        final data = decoded['data'] as Map;
        List<String> parts = [];
        data.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            parts.add('$key: ${value.join(", ")}');
          }
        });
        return parts.isEmpty ? 'Non défini' : parts.join(' | ');
      }
      if (decoded is List) {
        return decoded.join(', ');
      }
      return decoded.toString();
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle,
      {VoidCallback? onTap, bool isDestructive = false, bool isSuccess = false}) {
    Color color = isDestructive ? Colors.red : AppColors.forest;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDestructive ? Colors.red.withOpacity(0.1) : AppColors.warmWhite, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(color: isSuccess ? AppColors.sage : AppColors.mutedForeground, fontSize: 12, fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.black12, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, String currentDesc, String currentTimePrep, dynamic horairesRaw, BusinessDataProvider provider) {
    final descController = TextEditingController(text: currentDesc);
    final prepController = TextEditingController(text: currentTimePrep);

    // Opening hours state
    String hoursMode = 'all'; // 'all', 'split', 'custom'
    Map<String, List<String>> schedule = {
      'Tous les jours': [],
      'Lundi-Vendredi': [],
      'Samedi-Dimanche': [],
      'Lundi': [], 'Mardi': [], 'Mercredi': [], 'Jeudi': [], 'Vendredi': [], 'Samedi': [], 'Dimanche': []
    };

    // Attempt to parse existing data
    if (horairesRaw != null) {
      try {
        final decoded = horairesRaw is String ? jsonDecode(horairesRaw) : horairesRaw;
        if (decoded is Map) {
          hoursMode = decoded['mode'] ?? 'all';
          final data = decoded['data'] as Map;
          data.forEach((key, value) {
            if (schedule.containsKey(key)) {
              schedule[key] = List<String>.from(value);
            }
          });
        } else if (decoded is List) {
          schedule['Tous les jours'] = decoded.map((e) => e.toString()).toList();
          hoursMode = 'all';
        }
      } catch (_) {
        if (horairesRaw is String && horairesRaw.isNotEmpty) {
           schedule['Tous les jours'] = [horairesRaw];
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          List<String> activeKeys = [];
          if (hoursMode == 'all') activeKeys = ['Tous les jours'];
          else if (hoursMode == 'split') activeKeys = ['Lundi-Vendredi', 'Samedi-Dimanche'];
          else activeKeys = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Modifier les informations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forest)),
                  const SizedBox(height: 24),
                  _buildEditField('Description', descController, maxLines: 3),
                  const SizedBox(height: 16),
                  _buildEditField('Temps de préparation (mins)', prepController, isNumber: true),
                  const SizedBox(height: 24),

                  const Text('Configuration des horaires', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 14)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _hoursModeChip('Tous les jours', 'all', hoursMode, (val) => setModalState(() => hoursMode = val)),
                        _hoursModeChip('Semaine/Weekend', 'split', hoursMode, (val) => setModalState(() => hoursMode = val)),
                        _hoursModeChip('Par jour', 'custom', hoursMode, (val) => setModalState(() => hoursMode = val)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ...activeKeys.map((dayKey) {
                    final slots = schedule[dayKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(dayKey, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 13)),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                final start = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                                if (start == null) return;
                                final end = await showTimePicker(context: context, initialTime: TimeOfDay(hour: start.hour + 8, minute: 0));
                                if (end == null) return;
                                final fmt = (TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                                setModalState(() => schedule[dayKey]!.add('${fmt(start)}-${fmt(end)}'));
                              },
                              child: const Text('+ Ajouter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (slots.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text('Aucun horaire défini', style: TextStyle(color: AppColors.mutedForeground, fontSize: 11, fontStyle: FontStyle.italic)),
                          ),
                        ...slots.asMap().entries.map((e) {
                          final i = e.key;
                          final s = e.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 14, color: AppColors.forest),
                                const SizedBox(width: 8),
                                Text(s, style: const TextStyle(fontSize: 12, color: AppColors.forest)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setModalState(() => schedule[dayKey]!.removeAt(i)),
                                  child: const Icon(LucideIcons.x, size: 14, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 24),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _isSwitching = true);
                        
                        // Clean up schedule based on mode
                        Map<String, List<String>> finalData = {};
                        for (var key in activeKeys) {
                          finalData[key] = schedule[key]!;
                        }

                        await provider.updateProfile({
                          'description': descController.text.trim(),
                          'temps_preparation': int.tryParse(prepController.text.trim()) ?? 15,
                          'opening_hours': jsonEncode({'mode': hoursMode, 'data': finalData}),
                        });
                        setState(() => _isSwitching = false);
                      },
                      child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _hoursModeChip(String label, String value, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.forest : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.forest, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// ─── Business Addresses Screen ──────────────────────────────────────────────
class BusinessAddressesScreen extends StatefulWidget {
  final BusinessDataProvider provider;
  const BusinessAddressesScreen({super.key, required this.provider});

  @override
  State<BusinessAddressesScreen> createState() => _BusinessAddressesScreenState();
}

class _BusinessAddressesScreenState extends State<BusinessAddressesScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addrs = await widget.provider.apiService.getAddresses();
    if (mounted) setState(() { _addresses = addrs; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Adresse du Business', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.forest,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.forest))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 60, color: AppColors.mutedForeground),
                      const SizedBox(height: 16),
                      const Text('Aucune adresse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Ajoutez l\'adresse de votre établissement', style: TextStyle(color: AppColors.mutedForeground)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) => _buildAddressTile(_addresses[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddSheet(),
      ),
    );
  }

  Widget _buildAddressTile(Map<String, dynamic> rel) {
    final isDefault = rel['is_default'] == true;
    final adr = rel['adresse'] ?? {};
    final title = rel['titre'] ?? (isDefault ? 'Adresse Principale' : 'Adresse');
    final details = adr['details']?.toString().isNotEmpty == true ? adr['details'] : adr['ville'] ?? 'Inconnue';
    final idAddress = rel['id_adresse'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDefault ? AppColors.forest : AppColors.border, width: isDefault ? 2 : 1),
        boxShadow: isDefault ? [BoxShadow(color: AppColors.forest.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDefault ? AppColors.forest.withOpacity(0.1) : AppColors.background, shape: BoxShape.circle),
          child: Icon(isDefault ? Icons.store : Icons.location_on, color: isDefault ? AppColors.forest : AppColors.mutedForeground),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(4)),
                child: const Text('Principale', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(details, style: const TextStyle(color: AppColors.mutedForeground, height: 1.4)),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.mutedForeground),
          onSelected: (value) async {
            if (value == 'default') {
              final ok = await widget.provider.apiService.updateAddress(idAddress, {'is_default': true});
              if (ok) await _loadAddresses();
            } else if (value == 'delete') {
              final ok = await widget.provider.apiService.deleteAddress(idAddress);
              if (ok) await _loadAddresses();
            }
          },
          itemBuilder: (ctx) => [
            if (!isDefault) const PopupMenuItem(value: 'default', child: Text('Définir par défaut')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppColors.destructive))),
          ],
        ),
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddAddressBottomSheet(
        onSave: (data) async {
          final ok = await widget.provider.apiService.addAddress(data);
          if (ok) await _loadAddresses();
          return ok;
        },
      ),
    );
  }
}
