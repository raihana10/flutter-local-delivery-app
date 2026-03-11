import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/constants/app_strings.dart';
import 'package:app/data/models/commande_model.dart';
import 'package:app/data/datasources/livreur_mock_datasource.dart';

class LivraisonActiveScreen extends StatefulWidget {
  final CommandeModel? commande;
  const LivraisonActiveScreen({super.key, this.commande});
  @override
  State<LivraisonActiveScreen> createState() => _LivraisonActiveScreenState();
}

class _LivraisonActiveScreenState extends State<LivraisonActiveScreen> {
  int _currentStep = 0;
  late CommandeModel _commande;
  final MapController _mapController = MapController();
  final LatLng _livreurPos = const LatLng(35.5740, -5.3680);

  @override
  void initState() {
    super.initState();
    _commande = widget.commande ?? LivreurMockDatasource.mockCommande;
  }

  LatLng get _restaurantPos => LatLng(_commande.latRestaurant ?? 35.5711, _commande.lngRestaurant ?? -5.3694);
  LatLng get _clientPos     => LatLng(_commande.latClient ?? 35.5750, _commande.lngClient ?? -5.3720);
  LatLng get _targetPos     => _currentStep == 0 ? _restaurantPos : _clientPos;

  void _confirmerEtape() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Prise en charge confirmée ! Allez livrer le client.'),
        backgroundColor: AppColors.navyDark,
      ));
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Livraison terminée ! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Vous avez gagné ${_commande.prix.toStringAsFixed(0)} MAD', style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Retour au tableau de bord', style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A2340) : Colors.white;
    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(children: [
        _buildHeader(surfaceColor),
        Expanded(flex: 5, child: _buildMap()),
        _buildBottomPanel(surfaceColor),
      ]),
    );
  }

  Widget _buildHeader(Color surfaceColor) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
      color: surfaceColor,
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, size: 20, color: AppColors.navyDark),
            ),
          ),
          const SizedBox(width: 12),
          const Text(AppStrings.livraisonActive, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyDark)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _StepChip(index: 1, label: AppStrings.allerAuRestaurant, isActive: _currentStep == 0, isDone: _currentStep > 0),
          const SizedBox(width: 8),
          _StepChip(index: 2, label: AppStrings.livrerAuClient, isActive: _currentStep == 1, isDone: false),
        ]),
      ]),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _livreurPos, initialZoom: 14.5),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.app'),
        PolylineLayer(polylines: [Polyline(points: [_livreurPos, _targetPos], color: AppColors.yellow, strokeWidth: 4, isDotted: true)]),
        MarkerLayer(markers: [
          Marker(point: _livreurPos, width: 40, height: 40,
              child: Container(decoration: BoxDecoration(color: AppColors.navyDark, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.directions_bike, color: Colors.white, size: 20))),
          Marker(point: _restaurantPos, width: 40, height: 40,
              child: Container(decoration: BoxDecoration(color: _currentStep == 0 ? AppColors.yellow : AppColors.online, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: Icon(_currentStep == 0 ? Icons.restaurant : Icons.check, color: AppColors.navyDark, size: 20))),
          if (_currentStep == 1)
            Marker(point: _clientPos, width: 40, height: 40,
                child: Container(decoration: BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.person_pin_circle, color: AppColors.navyDark, size: 20))),
        ]),
      ],
    );
  }

  Widget _buildBottomPanel(Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(color: surfaceColor, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.restaurant_menu, color: AppColors.navyDark, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_commande.restaurant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyDark)),
            Text(_commande.adresse, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          Text('${_commande.distance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ouverture de la navigation...'))),
              icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
              label: const Text(AppStrings.ouvrirNavigation, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              onPressed: _confirmerEtape,
              child: Text(_currentStep == 0 ? AppStrings.confirmerPriseEnCharge : AppStrings.confirmerLivraison,
                  style: const TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.bold, fontSize: 15)),
            )),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ContactButton(icon: Icons.phone, onTap: () {}),
          const SizedBox(width: 12),
          _ContactButton(icon: Icons.chat_bubble_outline, onTap: () {}),
        ]),
      ]),
    );
  }
}

class _StepChip extends StatelessWidget {
  final int index; final String label; final bool isActive; final bool isDone;
  const _StepChip({required this.index, required this.label, required this.isActive, required this.isDone});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navyDark : isDone ? AppColors.online.withValues(alpha: 0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 18, height: 18,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? AppColors.yellow : isDone ? AppColors.online : AppColors.textSecondary.withValues(alpha: 0.3)),
              child: Center(child: isDone ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : Text('$index', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppColors.navyDark : AppColors.textSecondary)))),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
        child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: AppColors.navyDark, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)));
  }
}