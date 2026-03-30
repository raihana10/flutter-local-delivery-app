import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/constants/app_strings.dart';
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

  LatLng? _businessPos;
  LatLng? _clientPos;
  LatLng? _riderPos;
  LatLng? _gpsPos;

  String _businessName = 'Commerce';
  String _businessAddress = 'Chargement...';
  double _distanceToClient = 0.0;

  bool _isLoading = true;
  String _status = 'Recherche de la commande...';
  int _currentStep = 0; // 0=Confirmé, 1=Préparé, 2=En route, 3=Livré

  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _livreurData;
  RealtimeChannel? _orderChannel;
  RealtimeChannel? _timelineChannel;

  @override
  void initState() {
    super.initState();
    _fetchGpsLocation();
    _fetchOrderData();
    _setupRealtime();
  }

  @override
  void dispose() {
    _orderChannel?.unsubscribe();
    _timelineChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    final supabase = Supabase.instance.client;
    
    _orderChannel = supabase
        .channel('order_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'commande',
          callback: (payload) => _fetchOrderData(),
        )
        .subscribe();

    _timelineChannel = supabase
        .channel('timeline_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'timeline',
          callback: (payload) => _fetchOrderData(),
        )
        .subscribe();
  }

  Future<void> _fetchGpsLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _gpsPos = LatLng(position.latitude, position.longitude);
          _clientPos ??= _gpsPos;
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

      const selectQuery = '''
        *,
        adresse(id_adresse, latitude, longitude, ville),
        timeline(position_order, livreur(app_user(nom, num_tl)))
      ''';

      if (widget.orderId != null) {
        data = await supabase
            .from('commande')
            .select(selectQuery)
            .eq('id_commande', widget.orderId!)
            .maybeSingle();
      } else if (clientId != null) {
        final response = await supabase
            .from('commande')
            .select(selectQuery)
            .eq('id_client', clientId)
            .inFilter('statut_commande', ['confirmee', 'preparee', 'en_livraison', 'livree'])
            .order('created_at', ascending: false)
            .limit(1);
        if (response.isNotEmpty) data = response.first;
      }

      if (data != null && mounted) {
        final orderId = data['id_commande'];

        // 1. Client Coords
        LatLng? clientLatLng;
        final adr = data['adresse'];
        if (adr is Map) {
          final lat = double.tryParse(adr['latitude']?.toString() ?? '');
          final lng = double.tryParse(adr['longitude']?.toString() ?? '');
          if (lat != null && lng != null) clientLatLng = LatLng(lat, lng);
        }

        // 2. Business Coords & Info (Still separate find for business via lines)
        LatLng? bizLatLng;
        String bizName = 'Commerce';
        String bizAddr = 'Adresse indisponible';
        
        try {
          final lines = await supabase
              .from('ligne_commande')
              .select('id_produit, produit(id_business, business(id_business, app_user(nom, user_adresse(adresse(*)))))')
              .eq('id_commande', orderId)
              .limit(1);
          
          if (lines.isNotEmpty) {
            final produitData = lines.first['produit'];
            final biz = produitData?['business']?['app_user'];
            
            if (biz != null) {
              bizName = biz['nom'] ?? 'Commerce';
              final uaRaw = biz['user_adresse'];
              Map<String, dynamic>? adrData;
              
              if (uaRaw is List && uaRaw.isNotEmpty) {
                // Find default address or just take the first one
                final defaultAdr = uaRaw.firstWhere((a) => a['is_default'] == true, orElse: () => uaRaw.first);
                adrData = defaultAdr['adresse'];
              } else if (uaRaw is Map) {
                adrData = uaRaw['adresse'];
              }

              if (adrData != null) {
                bizAddr = adrData['ville'] ?? 'Ville inconnue';
                final lat = double.tryParse(adrData['latitude']?.toString() ?? '');
                final lng = double.tryParse(adrData['longitude']?.toString() ?? '');
                if (lat != null && lng != null) {
                  bizLatLng = LatLng(lat, lng);
                  debugPrint('TRACKER: Found business location: $bizLatLng');
                } else {
                   debugPrint('TRACKER: Lat/Lng parsing failed for business: $lat, $lng');
                }
              } else {
                debugPrint('TRACKER: No address data found in user_adresse for business');
              }
            } else {
               debugPrint('TRACKER: Business app_user not found in join');
            }
          } else {
             debugPrint('TRACKER: No order lines found');
          }
        } catch (e) {
          debugPrint('TRACKER: Biz fetch error: $e');
        }

        // 3. Rider Coords & Info
        LatLng? riderLatLng;
        Map<String, dynamic>? livreurData;

        final tlRaw = data['timeline'];
        Map<String, dynamic>? tl;
        if (tlRaw is List && tlRaw.isNotEmpty) {
          final found = tlRaw.firstWhere(
            (t) => t['position_order'] != null,
            orElse: () => tlRaw.first
          );
          if (found != null) tl = Map<String, dynamic>.from(found);
        } else if (tlRaw is Map) {
          tl = Map<String, dynamic>.from(tlRaw);
        }

        if (tl != null) {
          final pos = tl['position_order'];
          if (pos is Map) {
            final lat = double.tryParse(pos['latitude']?.toString() ?? '');
            final lng = double.tryParse(pos['longitude']?.toString() ?? '');
            if (lat != null && lng != null && lat != 0 && lng != 0) {
              riderLatLng = LatLng(lat, lng);
            }
          }
          final livRaw = tl['livreur'];
          if (livRaw is Map) livreurData = Map<String, dynamic>.from(livRaw);
        }

        // --- IMPROVED FALLBACK LOGIC ---
        final status = data['statut_commande'] as String? ?? '';
        bool isMock = false;
        if (riderLatLng == null && livreurData != null) {
          if (status == 'confirmee' || status == 'preparee') {
            riderLatLng = bizLatLng;
            isMock = true;
          } else if (status == 'en_livraison' && bizLatLng != null && clientLatLng != null) {
            // Mock at 50% distance if en_route but no GPS yet
            riderLatLng = LatLng(
              bizLatLng.latitude + (clientLatLng.latitude - bizLatLng.latitude) * 0.5,
              bizLatLng.longitude + (clientLatLng.longitude - bizLatLng.longitude) * 0.5,
            );
            isMock = true;
          }
        }
        
        if (riderLatLng != null) {
          debugPrint('TRACKER: Showing rider at $riderLatLng (${isMock ? 'MOCK' : 'LIVE'})');
        }

        int step = 0;
        String statusText = 'Commande confirmée';
        if (status == 'preparee') {
          step = 1;
          statusText = 'En préparation';
        } else if (status == 'en_livraison') {
          step = 2;
          statusText = 'En cours de livraison';
        } else if (status == 'livree') {
          step = 3;
          statusText = 'Livraison terminée';
        }

        double dist = 0.0;
        if (clientLatLng != null && bizLatLng != null) {
          dist = Geolocator.distanceBetween(
                clientLatLng.latitude, clientLatLng.longitude,
                bizLatLng.latitude, bizLatLng.longitude) / 1000.0;
        }

        if (mounted) {
          setState(() {
            _orderData = data;
            _livreurData = livreurData;
            _clientPos = clientLatLng ?? _gpsPos;
            _businessPos = bizLatLng;
            _riderPos = riderLatLng;
            _businessName = bizName;
            _businessAddress = bizAddr;
            _distanceToClient = dist;
            _currentStep = step;
            _status = statusText;
            _isLoading = false;
          });
          _fitBounds();
        }
      } else if (mounted) {
        setState(() {
          _status = 'Aucune commande trouvée';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('OrderTracking Error: $e');
      if (mounted) {
        setState(() {
          _status = 'Erreur: ${e.toString().split('\n').first}';
          _isLoading = false;
        });
      }
    }
  }

  void _fitBounds() {
    if (_clientPos == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      List<LatLng> points = [_clientPos!];
      if (_businessPos != null) points.add(_businessPos!);
      if (_riderPos != null) points.add(_riderPos!);

      try {
        if (points.length == 1) {
          _mapController.move(points.first, 15.0);
        } else {
          double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
          double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
          double minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
          double maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
          
          _mapController.move(LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2), 13.5);
        }
      } catch (err) {
        debugPrint('MapController not ready yet: $err');
      }
    });
  }

  Future<void> _callLivreur() async {
    if (_livreurData == null || _livreurData!['app_user'] == null) return;
    final phone = _livreurData!['app_user']['num_tl'];
    if (phone == null) return;
    final url = Uri(scheme: 'tel', path: phone.toString());
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_orderData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_status, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A2340) : Colors.white;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          _buildHeader(surfaceColor),
          Expanded(child: _buildMap()),
          _buildBottomPanel(surfaceColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color surfaceColor) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12),
      color: surfaceColor,
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: AppColors.navyDark),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Suivi de la livraison',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _StepChip(index: 1, label: 'Validée', isActive: _currentStep == 0, isDone: _currentStep > 0),
          const SizedBox(width: 4),
          _StepChip(index: 2, label: 'Préparée', isActive: _currentStep == 1, isDone: _currentStep > 1),
          const SizedBox(width: 4),
          _StepChip(index: 3, label: 'En route', isActive: _currentStep == 2, isDone: _currentStep > 2),
          const SizedBox(width: 4),
          _StepChip(index: 4, label: 'Livrée', isActive: _currentStep == 3, isDone: false),
        ]),
      ]),
    );
  }

  Widget _buildMap() {
    final targetPos = _currentStep < 2 ? _businessPos : _clientPos;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _riderPos ?? _clientPos ?? const LatLng(35.5750, -5.3720),
        initialZoom: 14.5,
      ),
      children: [
        TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app'),
        if (_riderPos != null && targetPos != null)
          PolylineLayer(polylines: [
            Polyline(
                points: [_riderPos!, targetPos],
                color: AppColors.yellow,
                strokeWidth: 4,
                isDotted: true)
          ]),
        MarkerLayer(markers: [
          if (_clientPos != null)
            Marker(
                point: _clientPos!,
                width: 44,
                height: 44,
                child: _buildMarkerWidget(Icons.home, AppColors.navyDark)),
          if (_businessPos != null)
            Marker(
                point: _businessPos!,
                width: 44,
                height: 44,
                child: _buildMarkerWidget(Icons.store, AppColors.accent)),
          if (_riderPos != null)
            Marker(
                point: _riderPos!,
                width: 50,
                height: 50,
                child: _buildMarkerWidget(Icons.delivery_dining, AppColors.online)),
        ]),
      ],
    );
  }

  Widget _buildMarkerWidget(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))
          ]),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildBottomPanel(Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(color: surfaceColor, boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))
      ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.store,
                      color: AppColors.navyDark, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_businessName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.navyDark)),
                    Text(_businessAddress,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ])),
              Text('${_distanceToClient.toStringAsFixed(1)} km',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  onPressed: () async {
                    final pos = _riderPos ?? _businessPos;
                    if (pos == null) return;
                    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${pos.latitude},${pos.longitude}&travelmode=driving');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.map, color: Colors.white, size: 18),
                  label: const Text('Ouvrir dans Google Maps',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                )),
            const SizedBox(height: 10),
            if (_livreurData != null)
              Row(
                children: [
                  GestureDetector(
                    onTap: _callLivreur,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          color: AppColors.yellow, shape: BoxShape.circle),
                      child: const Icon(Icons.phone, color: AppColors.navyDark, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Votre livreur', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          _livreurData!['app_user']?['nom'] ?? 'Chargement...', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyDark, fontSize: 15)
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(_status, 
                      style: const TextStyle(color: AppColors.online, fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_status, 
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (_currentStep == 3) ...[
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.online,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Arrêter le suivi',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  )),
            ],
          ]),
    );
  }
}

class _StepChip extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isDone;
  const _StepChip({required this.index, required this.label, required this.isActive, required this.isDone});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navyDark : isDone ? AppColors.online.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isDone)
            const Icon(Icons.check, size: 12, color: AppColors.online)
          else
            Text('$index', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppColors.yellow : AppColors.textSecondary)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

