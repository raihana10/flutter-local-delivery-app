import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ClientPaymentMethodsScreen extends StatefulWidget {
  const ClientPaymentMethodsScreen({super.key});

  @override
  State<ClientPaymentMethodsScreen> createState() => _ClientPaymentMethodsScreenState();
}

class _ClientPaymentMethodsScreenState extends State<ClientPaymentMethodsScreen> {
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'type': 'Cash',
      'title': 'Paiement à la livraison',
      'subtitle': 'Payez en espèces au livreur',
      'icon': Icons.money,
      'is_default': true,
      'color': Colors.green,
    },
    {
      'id': 'card_1',
      'type': 'Card',
      'title': 'Carte Bancaire',
      'subtitle': '**** **** **** 4242',
      'icon': Icons.credit_card,
      'is_default': false,
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Moyens de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          return _buildPaymentMethodItem(method);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardBottomSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_card, color: AppColors.card),
        label: const Text('Ajouter une carte', style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method) {
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
                child: const Text('Par défaut', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
        trailing: method['type'] == 'Cash' ? null : PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.mutedForeground),
          onSelected: (value) {
            if (value == 'default') {
              setState(() {
                for (var m in _paymentMethods) {
                  m['is_default'] = m['id'] == method['id'];
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moyen de paiement principal mis à jour')));
            } else if (value == 'delete') {
              setState(() {
                _paymentMethods.removeWhere((m) => m['id'] == method['id']);
                // if we deleted the default, make cash default
                if (method['is_default'] && _paymentMethods.isNotEmpty) {
                  _paymentMethods.firstWhere((m) => m['type'] == 'Cash')['is_default'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carte supprimée')));
            }
          },
          itemBuilder: (context) => [
            if (!method['is_default'])
              const PopupMenuItem(value: 'default', child: Text('Définir par défaut')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer', style: TextStyle(color: AppColors.destructive)),
            ),
          ],
        ),
        onTap: () {
          if (!method['is_default']) {
            setState(() {
              for (var m in _paymentMethods) {
                m['is_default'] = m['id'] == method['id'];
              }
            });
          }
        },
      ),
    );
  }

  void _showAddCardBottomSheet() {
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
                'Ajouter une carte bancaire',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Numéro de carte',
                  prefixIcon: const Icon(Icons.credit_card),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Date d\'expiration (MM/AA)',
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'CVC',
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nom sur la carte',
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
                  setState(() {
                    for (var m in _paymentMethods) { m['is_default'] = false; }
                    _paymentMethods.add({
                      'id': 'card_${DateTime.now().millisecondsSinceEpoch}',
                      'type': 'Card',
                      'title': 'Carte Bancaire',
                      'subtitle': '**** **** **** 8888',
                      'icon': Icons.credit_card,
                      'is_default': true,
                      'color': AppColors.primary,
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carte ajoutée avec succès')));
                },
                child: const Text('Ajouter cette carte', style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
