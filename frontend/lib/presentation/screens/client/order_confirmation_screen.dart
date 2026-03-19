import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../core/providers/client_data_provider.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  int _selectedAddressIndex = 0;
  int _selectedPaymentMethod = 0;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': 'Paiement à la livraison',
      'icon': Icons.money,
      'color': Colors.green,
    },
    {
      'title': 'Carte bancaire',
      'icon': Icons.credit_card,
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final clientData = context.watch<ClientDataProvider>();
    final addresses = clientData.addresses;
    final cartItems = clientData.cartItems;
    
    double subtotal = clientData.cartSubtotal;
    double deliveryFee = 10.0;
    double total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Adresse de livraison', Icons.location_on),
                const SizedBox(height: 12),
                if (addresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Aucune adresse disponible', style: TextStyle(color: AppColors.mutedForeground)),
                  )
                else
                  ...List.generate(
                    addresses.length,
                    (index) => _buildAddressItem(index, addresses[index]),
                  ),
                TextButton.icon(
                  onPressed: _showAddAddressBottomSheet,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  label: const Text('Ajouter une nouvelle adresse', style: TextStyle(color: AppColors.primary)),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Mode de paiement', Icons.payment),
                const SizedBox(height: 12),
                ...List.generate(
                  _paymentMethods.length,
                  (index) => _buildPaymentMethod(index, _paymentMethods[index]),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Récapitulatif', Icons.receipt_long),
                const SizedBox(height: 12),
                _buildOrderSummaryWidget(cartItems.length, subtotal, deliveryFee, total),
                
                const SizedBox(height: 100), // padding bottom
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildConfirmationBar(total, addresses.isEmpty ? null : addresses[_selectedAddressIndex]),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressItem(int index, dynamic addressRelation) {
    bool isSelected = _selectedAddressIndex == index;
    final isDefault = addressRelation['is_default'] == true;
    final addressModel = addressRelation['adresse'] ?? {};
    final ville = addressModel['ville'] ?? 'Adresse';
    final title = isDefault ? 'Adresse Principale' : 'Nouvelle Adresse';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDefault ? Icons.home : Icons.location_on,
                color: isSelected ? AppColors.card : AppColors.mutedForeground,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppColors.primary : AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ville,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(int index, Map<String, dynamic> method) {
    bool isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: method['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'],
                color: method['color'],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? AppColors.primary : AppColors.foreground,
                ),
              ),
            ),
            Radio(
              value: index,
              groupValue: _selectedPaymentMethod,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryWidget(int itemsCount, double subtotal, double deliveryFee, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemsCount articles', style: TextStyle(color: AppColors.mutedForeground)),
              Text('$subtotal DH', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Livraison', style: TextStyle(color: AppColors.mutedForeground)),
              Text('$deliveryFee DH', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total à Payer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('$total DH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationBar(double total, dynamic selectedAddress) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          )
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
          ),
          onPressed: _isSubmitting ? null : () async {
            if (selectedAddress == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une adresse')));
              return;
            }
            
            setState(() { _isSubmitting = true; });

            final clientData = context.read<ClientDataProvider>();
            final cartItems = clientData.cartItems;
            
            final payload = {
              'id_adresse': selectedAddress['id_adresse'],
              'type_commande': 'food_delivery',
              'items': cartItems.map((item) {
                return {
                  'quantite': item['quantity'],
                  'id_produit': item['id'], // Assumes item has an id, fallback to 1 or something if mocked earlier
                  'prix_snapshot': item['price'],
                  'nom_snapshot': item['name']
                };
              }).toList(),
            };
            
            final success = await clientData.apiService.createOrder(payload);
            
            if (mounted) {
              setState(() { _isSubmitting = false; });
              if (success != null) {
                clientData.clearCart();
                _showSuccessDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la création de la commande')));
              }
            }
          },
          child: _isSubmitting ? const CircularProgressIndicator(color: AppColors.card) : Text(
            'Confirmer la commande ($total DH)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Commande Confirmée !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre commande a été envoyée avec succès. Vous recevrez une notification lorsque le livreur sera en route.',
              style: TextStyle(color: AppColors.mutedForeground, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Navigate back to home (pop everything)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Retour à l\'accueil', style: TextStyle(color: AppColors.card)),
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
