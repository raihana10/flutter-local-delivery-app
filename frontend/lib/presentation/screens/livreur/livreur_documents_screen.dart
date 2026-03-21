import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';

class LivreurDocumentsScreen extends StatefulWidget {
  const LivreurDocumentsScreen({super.key});

  @override
  State<LivreurDocumentsScreen> createState() => _LivreurDocumentsScreenState();
}

class _LivreurDocumentsScreenState extends State<LivreurDocumentsScreen> {
  Map<String, dynamic>? _livreurData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLivreurData();
  }

  Future<void> _fetchLivreurData() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('livreur')
            .select('cni, type_vehicule, permis_conduire_image, cni_recto_image, cni_verso_image')
            .eq('id_user', user.id)
            .maybeSingle();
            
        if (mounted) {
          setState(() {
            _livreurData = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadDocument(String columnName, String title) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) throw Exception('Utilisateur non connecté');

      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      // create a unique file name
      final fileName = '${user.id}_${columnName}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '${user.id}/$fileName';

      // Upload to Supabase Storage using bytes for Web compatibility
      await Supabase.instance.client.storage
          .from('livreur_documents')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      // Get public URL (though we use signed URL for private bucket,
      // creating a signed URL is temporary, we just save the path to the DB)
      
      // Update database
      await Supabase.instance.client
          .from('livreur')
          .update({columnName: path})
          .eq('id_user', user.id);

      // Refresh data
      await _fetchLivreurData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title téléchargé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement : ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Véhicule et documents', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: 'Type de véhicule',
              value: _livreurData?['type_vehicule'] ?? 'Non renseigné',
              icon: Icons.two_wheeler,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Numéro de permis (CNI)',
              value: _livreurData?['cni'] ?? 'Non renseigné',
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 24),
            const Text(
              'Documents téléchargés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            _buildDocumentItem(
              title: 'Permis de conduire',
              status: _livreurData?['permis_conduire_image'] != null ? 'Téléchargé' : 'Manquant',
              isVerified: _livreurData?['permis_conduire_image'] != null,
              onTap: () => _pickAndUploadDocument('permis_conduire_image', 'Permis de conduire'),
            ),
            _buildDocumentItem(
              title: 'Carte d\'identité (Recto)',
              status: _livreurData?['cni_recto_image'] != null ? 'Téléchargé' : 'Manquant',
              isVerified: _livreurData?['cni_recto_image'] != null,
              onTap: () => _pickAndUploadDocument('cni_recto_image', 'Carte d\'identité (Recto)'),
            ),
            _buildDocumentItem(
              title: 'Carte d\'identité (Verso)',
              status: _livreurData?['cni_verso_image'] != null ? 'Téléchargé' : 'Manquant',
              isVerified: _livreurData?['cni_verso_image'] != null,
              onTap: () => _pickAndUploadDocument('cni_verso_image', 'Carte d\'identité (Verso)'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Terminer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.card),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem({required String title, required String status, required bool isVerified, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVerified ? Colors.green.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.fileText,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: isVerified ? Colors.green : AppColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isVerified)
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
            else
              const Icon(Icons.upload, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
