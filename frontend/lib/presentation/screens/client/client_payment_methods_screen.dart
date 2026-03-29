import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/client_data_provider.dart';

class ClientPaymentMethodsScreen extends StatefulWidget {
  const ClientPaymentMethodsScreen({super.key});

  @override
  State<ClientPaymentMethodsScreen> createState() =>
      _ClientPaymentMethodsScreenState();
}

class _ClientPaymentMethodsScreenState
    extends State<ClientPaymentMethodsScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientDataProvider>().fetchPaymentMethods();
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientDataProvider>();
    final methods = provider.paymentMethods;
    final isLoading = provider.isLoading;

    final hasDefaultCard = methods.any((m) => m['is_default'] == true);
    final isCashDefault = provider.preferredPaymentMethod == 'cash' || (!hasDefaultCard && provider.preferredPaymentMethod == null);

    final cashMethod = {
      'id': 'cash',
      'type': 'Cash',
      'title': 'Paiement à la livraison',
      'subtitle': 'Payez en espèces au livreur',
      'icon': Icons.money,
      'is_default': isCashDefault,
      'color': Colors.green,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Moyens de paiement',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading && methods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<ClientDataProvider>().fetchPaymentMethods();
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPaymentMethodItem(cashMethod, isLocal: true),
                  ...methods.map((method) {
                    final isDefault = method['is_default'] == true && provider.preferredPaymentMethod != 'cash';
                    final String cardNum =
                        method['numero_carte']?.toString() ?? '****';
                    final String last4 = cardNum.length > 4
                        ? cardNum.substring(cardNum.length - 4)
                        : cardNum;

                    return _buildPaymentMethodItem({
                      'id': method['id_carte'].toString(),
                      'type': 'Card',
                      'title': 'Carte Bancaire',
                      'subtitle': '**** **** **** $last4',
                      'icon': Icons.credit_card,
                      'is_default': isDefault,
                      'color': AppColors.primary,
                    }, isLocal: false);
                  }).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardBottomSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_card, color: AppColors.card),
        label: const Text('Ajouter une carte',
            style:
                TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method,
      {required bool isLocal}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: method['is_default'] ? AppColors.accent : AppColors.border,
          width: method['is_default'] ? 2 : 1,
        ),
        boxShadow: [
          if (method['is_default'])
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
            color: method['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(method['icon'], color: method['color']),
        ),
        title: Row(
          children: [
            Text(
              method['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (method['is_default']) ...[
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
            method['subtitle'],
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
        ),
        trailing: isLocal
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.mutedForeground),
                onSelected: (value) async {
                  if (value == 'default') {
                    final success = await context
                        .read<ClientDataProvider>()
                        .setDefaultPaymentMethod(method['id']);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Moyen de paiement principal mis à jour')));
                    }
                  } else if (value == 'delete') {
                    final success = await context
                        .read<ClientDataProvider>()
                        .deletePaymentMethod(method['id']);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Carte supprimée')));
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (!method['is_default'])
                    const PopupMenuItem(
                        value: 'default', child: Text('Définir par défaut')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer',
                        style: TextStyle(color: AppColors.destructive)),
                  ),
                ],
              ),
        onTap: () async {
          if (!method['is_default']) {
            await context
                .read<ClientDataProvider>()
                .setDefaultPaymentMethod(method['id']);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Moyen de paiement principal mis à jour')));
            }
          }
        },
      ),
    );
  }

  void _showAddCardBottomSheet() {
    _cardNumberController.clear();
    _expiryController.clear();
    _nameController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ajouter une carte bancaire',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Numéro de carte',
                  prefixIcon: const Icon(Icons.credit_card),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Date d\'expiration (MM/AA)',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom sur la carte',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (_cardNumberController.text.isEmpty ||
                      _expiryController.text.isEmpty) {
                    return;
                  }

                  final data = {
                    'numero_carte': _cardNumberController.text.trim(),
                    'date_expiration': _expiryController.text.trim(),
                    'nom_carte': _nameController.text.trim(),
                    'is_default': true,
                  };

                  Navigator.pop(ctx);
                  final success = await context
                      .read<ClientDataProvider>()
                      .addPaymentMethodCard(data);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Carte ajoutée avec succès')));
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Erreur lors de l\'ajout de la carte'),
                        backgroundColor: AppColors.destructive));
                  }
                },
                child: const Text('Ajouter cette carte',
                    style: TextStyle(
                        color: AppColors.card, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
