import 'package:flutter/material.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:app/core/providers/auth_provider.dart';

class LivreurDocumentsScreen extends StatelessWidget {
  const LivreurDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Véhicule et documents', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Utilisateur non connecté'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: Supabase.instance.client
                  .from('livreur')
                  .select()
                  .eq('id_user', user.id)
                  .maybeSingle(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Erreur lors du chargement des documents'));
                }

                final data = snapshot.data!;
                final bool isActif = data['est_actif'] == true || data['est_actif'] == 1;
                final cni = data['cni'] ?? '';

                // If the driver is active, we can assume documents are verified.
                // Otherwise, they are pending.
                final statusCni = isActif ? 'Vérifié' : (cni.toString().isNotEmpty ? 'En attente' : 'Non fourni');
                final isCniVerified = isActif;

                final statusGeneral = isActif ? 'Vérifié' : 'En attente';
                final isGeneralVerified = isActif;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statut de votre compte',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isActif ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isActif ? Colors.green : Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(isActif ? Icons.check_circle : Icons.pending, color: isActif ? Colors.green : Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(child: Text(isActif ? 'Compte validé. Vous pouvez effectuer des livraisons.' : 'Compte en attente de vérification par un administrateur.', style: TextStyle(color: isActif ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Mes documents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDocumentCard(
                        title: 'Document d\'identité (CNI/Passeport)',
                        status: statusCni,
                        icon: Icons.badge_outlined,
                        isVerified: isCniVerified,
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentCard(
                        title: 'Permis de conduire',
                        status: statusGeneral,
                        icon: Icons.drive_eta_outlined,
                        isVerified: isGeneralVerified,
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentCard(
                        title: 'Carte grise du véhicule',
                        status: statusGeneral,
                        icon: Icons.description_outlined,
                        isVerified: isGeneralVerified,
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentCard(
                        title: 'Assurance (Véhicule & Livreur)',
                        status: statusGeneral,
                        icon: Icons.shield_outlined,
                        isVerified: isGeneralVerified,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String status,
    required IconData icon,
    required bool isVerified,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
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
                    fontSize: 16,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle : (status == 'Non fourni' ? Icons.cancel : Icons.pending),
                      size: 16,
                      color: isVerified ? Colors.green : (status == 'Non fourni' ? Colors.red : Colors.orange),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        color: isVerified ? Colors.green : (status == 'Non fourni' ? Colors.red : Colors.orange),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mutedForeground),
        ],
      ),
    );
  }
}

