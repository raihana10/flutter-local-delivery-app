import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/core/constants/app_colors.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  final LatLng _restaurantPos = const LatLng(35.5711, -5.3694);
  final LatLng _clientPos = const LatLng(35.5750, -5.3720);
  LatLng _riderPos = const LatLng(35.5720, -5.3700);
  String _status = 'En cours de préparation';
  int _currentStep = 1; // 1: Preparation, 2: Picking up, 3: Delivery

  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    // Simulate rider movement
    _moveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStep == 1) {
          _status = 'Le livreur récupère votre commande';
          _currentStep = 2;
        } else if (_currentStep == 2) {
          _status = 'Le livreur est en route !';
          _currentStep = 3;
        }
        
        // Move rider closer to client
        double newLat = _riderPos.latitude + (_clientPos.latitude - _riderPos.latitude) * 0.2;
        double newLng = _riderPos.longitude + (_clientPos.longitude - _riderPos.longitude) * 0.2;
        _riderPos = LatLng(newLat, newLng);
      });
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
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
      body: Stack(
        children: [
          _buildMap(),
          _buildTrackingCard(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
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
    );
  }

  Widget _buildTrackingCard() {
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
                      const Text(
                        'Arrivée prévue dans 12 min',
                        style: TextStyle(
                            color: AppColors.mutedForeground, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatusTimeline(),
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondary,
                  child: Text('👨‍💼'),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmed D.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Livreur • ⭐ 4.9',
                        style: TextStyle(
                            color: AppColors.mutedForeground, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _ContactAction(icon: Icons.phone_outlined, onTap: () {}),
                const SizedBox(width: 8),
                _ContactAction(icon: Icons.chat_bubble_outline, onTap: () {}),
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
