import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/client_data_provider.dart';
import 'client_addresses_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  int _selectedAddressIndex = 0;
  int _selectedPaymentMethod = 0; // 0 = cash, 1 = card
  bool _isSubmitting = false;
  double? _distanceKm;
  final TextEditingController _monnaieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize payment method based on client's default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentMethod();
      _initializeInitialDistance();
    });
  }

  void _initializeInitialDistance() {
    final clientData = context.read<ClientDataProvider>();
    if (clientData.addresses.isNotEmpty) {
      setState(() {
        _distanceKm = _calcDistance(clientData.addresses, 0, clientData);
      });
    }
  }

  void _initializePaymentMethod() {
    final clientData = context.read<ClientDataProvider>();
    final paymentMethods = clientData.paymentMethods;
    
    // Check if there is a default payment card
    if (paymentMethods.isNotEmpty) {
      final defaultCard = paymentMethods.firstWhere(
        (m) => m['is_default'] == true,
        orElse: () => <String, dynamic>{},
      );
      
      if (defaultCard.isNotEmpty) {
        // If there's a default card, select 'card' payment method
        setState(() {
          _selectedPaymentMethod = 1; // card
        });
      } else {
        // Otherwise, default to cash
        setState(() {
          _selectedPaymentMethod = 0; // cash
        });
      }
    }
  }

  @override
  void dispose() {
    _monnaieController.dispose();
    super.dispose();
  }

  double? _calcDistance(List<dynamic> addresses, int idx, ClientDataProvider clientData) {
    if (idx < 0 || idx >= addresses.length) return null;
    final adresse = addresses[idx]['adresse'] ?? {};
    final clientLat = double.tryParse(adresse['latitude']?.toString() ?? '');
    final clientLng = double.tryParse(adresse['longitude']?.toString() ?? '');
    
    final cartItems = clientData.cartItems;
    if (cartItems.isEmpty) return null;

    // Check if this is a hybrid order (multiple business_ids)
    final businessIds = <String>{};
    for (var item in cartItems) {
      final bizId = item['business_id'];
      if (bizId != null) {
        businessIds.add(bizId.toString());
      }
    }

    // If single or no business_id tracked, use the single business address
    if (businessIds.length <= 1) {
      final businessAddr = clientData.businessAddress;
      final bizLat = double.tryParse(businessAddr?['latitude']?.toString() ?? '');
      final bizLng = double.tryParse(businessAddr?['longitude']?.toString() ?? '');
      if (clientLat != null && clientLng != null && bizLat != null && bizLng != null) {
        final meters = Geolocator.distanceBetween(bizLat, bizLng, clientLat, clientLng);
        return meters / 1000; // km
      }
    } else {
      // Hybrid order: calculate average distance from all businesses
      // For now, use the single business address as fallback
      // In production, you'd fetch all business addresses and average them
      final businessAddr = clientData.businessAddress;
      final bizLat = double.tryParse(businessAddr?['latitude']?.toString() ?? '');
      final bizLng = double.tryParse(businessAddr?['longitude']?.toString() ?? '');
      if (clientLat != null && clientLng != null && bizLat != null && bizLng != null) {
        final meters = Geolocator.distanceBetween(bizLat, bizLng, clientLat, clientLng);
        return meters / 1000; // km
      }
    }
    
    return null;
  }

  double _calculateDeliveryFee(double? distanceKm) {
    if (distanceKm == null || distanceKm <= 0) {
      return 1.5;
    }
    double baseFee = distanceKm * 1.5;
    
    // Custom rounding:
    // If decimal is between 0 and 0.5 -> 0.5
    // If decimal > 0.5 -> round up to next integer
    double integerPart = baseFee.truncateToDouble();
    double fraction = baseFee - integerPart;
    
    if (fraction == 0) return baseFee;
    if (fraction <= 0.5) return integerPart + 0.5;
    return integerPart + 1.0;
  }

  /// Check if the current cart contains items from multiple businesses
  bool _isHybridOrder(List<Map<String, dynamic>> cartItems) {
    if (cartItems.isEmpty) return false;
    final businessIds = <String>{};
    for (var item in cartItems) {
      final bizId = item['business_id'];
      if (bizId != null) {
        businessIds.add(bizId.toString());
      }
    }
    return businessIds.length > 1;
  }

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
    double deliveryFee = _calculateDeliveryFee(_distanceKm);
    double total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmation',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: Text('Aucune adresse disponible',
                        style: TextStyle(color: AppColors.mutedForeground)),
                  )
                else
                  ...List.generate(
                    addresses.length,
                    (index) => _buildAddressItem(index, addresses[index], clientData),
                  ),
                TextButton.icon(
                  onPressed: () => _showAddAddressBottomSheet(clientData),
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  label: const Text('Ajouter une nouvelle adresse',
                      style: TextStyle(color: AppColors.primary)),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Mode de paiement', Icons.payment),
                const SizedBox(height: 12),
                ...List.generate(
                  _paymentMethods.length,
                  (index) => _buildPaymentMethod(index, _paymentMethods[index]),
                ),
                // Monnaie donnée – visible only for cash payment
                if (_selectedPaymentMethod == 0) ...
                  [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monnaie à préparer',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Total à payer: $total DH – indiquez le montant que vous donnerez au livreur',
                              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _monnaieController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Ex: 200 DH',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixText: 'DH',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
      bottomNavigationBar: _buildConfirmationBar(
          total, addresses.isEmpty ? null : addresses[_selectedAddressIndex], clientData),
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

  Widget _buildAddressItem(int index, dynamic addressRelation, ClientDataProvider clientData) {
    bool isSelected = _selectedAddressIndex == index;
    final isDefault = addressRelation['is_default'] == true;
    final addressModel = addressRelation['adresse'] ?? {};
    final ville = addressModel['ville'] ?? 'Adresse';
    final details = addressModel['details'] ?? ville;
    
    // Fallback to title if available, otherwise default logic
    final title = addressRelation['titre'] ?? (isDefault ? 'Adresse Principale' : 'Nouvelle Adresse');

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressIndex = index;
          _distanceKm = _calcDistance(clientData.addresses, index, clientData);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.card,
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
                      color:
                          isSelected ? AppColors.primary : AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 28),
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
          color:
              isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.card,
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

  Widget _buildOrderSummaryWidget(
      int itemsCount, double subtotal, double deliveryFee, double total) {
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
              Text('$itemsCount articles',
                  style: TextStyle(color: AppColors.mutedForeground)),
              Text('$subtotal DH',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Livraison',
                  style: TextStyle(color: AppColors.mutedForeground)),
              Text('$deliveryFee DH',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total à Payer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('$total DH',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationBar(double total, dynamic selectedAddress, ClientDataProvider clientData) {
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
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (selectedAddress == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Veuillez sélectionner une adresse')));
                    return;
                  }

                  setState(() {
                    _isSubmitting = true;
                  });
                  final clientData = context.read<ClientDataProvider>();
                  final cartItems = clientData.cartItems;
                  final isHybrid = _isHybridOrder(cartItems);

                  // Sanitization for prix_donne
                  double? prixDonne;
                  if (_selectedPaymentMethod == 0) {
                    final raw = _monnaieController.text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
                    if (raw.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Veuillez indiquer le montant que vous donnerez au livreur')));
                      setState(() => _isSubmitting = false);
                      return;
                    }
                    prixDonne = double.tryParse(raw);
                    if (prixDonne == null || prixDonne < total) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Le montant doit être supérieur ou égal au total (${total.toStringAsFixed(2)} DH)')));
                      setState(() => _isSubmitting = false);
                      return;
                    }
                  }

                  final payload = {
                    'id_adresse': selectedAddress['id_adresse'] ?? selectedAddress['adresse']?['id_adresse'],
                    'type_commande': isHybrid ? 'hybride' : 'food_delivery',
                    'mode_paiement': _selectedPaymentMethod == 0 ? 'cash' : 'card',
                    if (_selectedPaymentMethod == 0)
                      'prix_donne': prixDonne,
                    if (_distanceKm != null)
                      'distance_km': double.parse(_distanceKm!.toStringAsFixed(2)),
                    'items': cartItems.map((item) {
                      return {
                        'quantite': item['quantity'],
                        'id_produit': item['id'],
                        'prix_snapshot': item['price'],
                        'nom_snapshot': item['name']
                      };
                    }).toList(),
                  };

                  final success =
                      await clientData.apiService.createOrder(payload);

                  if (mounted) {
                    setState(() {
                      _isSubmitting = false;
                    });
                    if (success != null) {
                      clientData.clearCart();
                      // Fetch notifications immediately to show the confirmation badge/notif
                      clientData.fetchNotifications();
                      _showSuccessDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Erreur lors de la création de la commande')));
                    }
                  }
                },
          child: _isSubmitting
              ? const CircularProgressIndicator(color: AppColors.card)
              : Text(
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
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Navigate back to home (pop everything)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Retour à l\'accueil',
                  style: TextStyle(color: AppColors.card)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressBottomSheet(ClientDataProvider clientData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddAddressBottomSheet(
          onSave: (data) async {
            // addAddress() internally calls fetchAddresses(), so no need to call it again
            final success = await clientData.addAddress(data);
            if (success && mounted) {
              // Auto-select the newly added address (last one)
              final newIdx = clientData.addresses.length - 1;
              setState(() {
                _selectedAddressIndex = newIdx < 0 ? 0 : newIdx;
                _distanceKm = _calcDistance(clientData.addresses, _selectedAddressIndex, clientData);
              });
            }
            return success;
          },
        );
      },
    );
  }
}
