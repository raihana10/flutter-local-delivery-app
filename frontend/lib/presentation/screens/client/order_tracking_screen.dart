import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng _restaurantPos = const LatLng(35.5711, -5.3694); // Fallback
  LatLng _clientPos = const LatLng(35.5750, -5.3720); // Fallback
  LatLng _riderPos = const LatLng(35.5720, -5.3700); // Fallback

  bool _isLoading = true;
  String _status = 'Recherche de la commande...';
  int _currentStep = 1; // 1: Preparation, 2: Picking up, 3: Delivery
  
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _livreurData;
  RealtimeChannel? _livreurChannel;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _fetchOrderData();
  }

  @override
  void dispose() {
    _livreurChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _clientPos = LatLng(position.latitude, position.longitude);
           _mapController.move(_clientPos, 15.0);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchOrderData() async {
    try {
      final supabase = Supabase.instance.client;
      final authProvider = context.read<AuthProvider>();
      final clientId = authProvider.roleId;

      Map<String, dynamic>? data;

      if (widget.orderId != null) {
        data = await supabase
            .from('commande')
            .select('*, timeline(*, livreur(*, app_user(*)))')
            .eq('id_commande', widget.orderId!)
            .maybeSingle();
      } else if (clientId != null) {
        // Find most recent active order
        final response = await supabase
            .from('commande')
            .select('*, timeline(*, livreur(*, app_user(*)))')
            .eq('id_client', clientId)
            .inFilter('statut_commande', ['confirmee', 'preparee', 'en_livraison'])
            .order('created_at', ascending: false)
            .limit(1);
        if (response.isNotEmpty) {
          data = response.first;
        }
      }

      if (data != null && mounted) {
        setState(() {
          _orderData = data;
          // Extract livreur from timeline relation
          _livreurData = data!['timeline'] != null ? data!['timeline']['livreur'] : null;
          
          final status = data!['statut_commande'] as String? ?? '';
          if (status == 'confirmee') {
            _currentStep = 1;
            _status = 'Commande confirmée';
          } else if (status == 'preparee') {
            _currentStep = 2;
            _status = 'Le commerçant prépare votre commande';
          } else if (status == 'en_livraison') {
            _currentStep = 3;
            _status = 'Le livreur est en route !';
          } else if (status == 'livree') {
            _currentStep = 3;
            _status = 'Commande livrée';
          }

          // If tracking coordinates exist, update them (mocking for now with static)
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _status = "Aucune commande active trouvée";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "Erreur de chargement";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callLivreur() async {
    if (_livreurData == null || _livreurData!['app_user'] == null) return;
    
    final phone = _livreurData!['app_user']['telephone'];
    if (phone == null || phone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
      return;
    }
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone.toString(),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de lancer l'appel")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suivi de commande',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchOrderData,
        backgroundColor: AppColors.navyDark,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Stack(
        children: [
          _buildMap(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_orderData == null)
            _buildEmptyStateCard()
          else
            _buildTrackingCard(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return ExcludeSemantics(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _clientPos,
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.livraison.app.frontend',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _clientPos,
              width: 45,
              height: 45,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
            if (_orderData != null)
              Marker(
                point: _restaurantPos,
                width: 45,
                height: 45,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 22),
                ),
              ),
            if (_livreurData != null && _orderData != null)
              Marker(
                point: _riderPos,
                width: 55,
                height: 55,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                     Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(Icons.delivery_dining, color: AppColors.primary, size: 28),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildEmptyStateCard() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.fastfood_outlined, size: 48, color: AppColors.mutedForeground.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              "Aucune commande à suivre",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Passez une commande pour commencer le suivi en temps réel.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard() {
    String livreurName = "En attente de livreur";
    String livreurRating = "N/A";
    if (_livreurData != null && _livreurData!['app_user'] != null) {
      livreurName = _livreurData!['app_user']['nom'] ?? livreurName;
      livreurRating = "Livreur • ⭐ 4.9"; // Mock rating until available in DB
    }

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.timer, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_orderData != null)
                        const Text(
                          'Arrivée prévue dans environ 15 min',
                          style: TextStyle(
                              color: AppColors.mutedForeground, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_orderData != null) ...[
              const SizedBox(height: 20),
              _buildStatusTimeline(),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                   Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                   SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Suivi en direct : Votre commande est gérée en temps réel. '
                       'Dès que le commerçant prépare votre colis, un livreur est assigné. '
                       'Vous recevrez des notifications à chaque changement de statut.',
                       style: TextStyle(fontSize: 11, color: AppColors.primary),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondary,
                  child: Text('👨‍💼'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        livreurName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        livreurRating,
                        style: const TextStyle(
                            color: AppColors.mutedForeground, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (_livreurData != null)
                  _ContactAction(icon: Icons.phone_outlined, onTap: _callLivreur),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatusDot(isDone: true),
            _buildStatusLine(isDone: true),
            _buildStatusDot(isDone: _currentStep >= 2),
            _buildStatusLine(isDone: _currentStep >= 3),
            _buildStatusDot(isDone: _currentStep >= 3),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Prep.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('En route', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Livré', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDot({required bool isDone}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary : Colors.grey.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusLine({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 3,
        color: isDone ? AppColors.primary : Colors.grey.withOpacity(0.3),
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ContactAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}
