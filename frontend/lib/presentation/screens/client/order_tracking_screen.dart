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

  // Positions — null jusqu'à ce qu'elles soient résolues depuis la BDD
  LatLng? _businessPos;    // coords réelles du business
  LatLng? _clientPos;      // coords réelles du client (depuis commande.adresse)
  LatLng? _riderPos;       // coords réelles du livreur (depuis timeline.position_order)
  LatLng? _gpsPos;         // position GPS live du téléphone (fallback)

  // Nom du business pour l'affichage
  String _businessName = 'Commerce';

  bool _isLoading = true;
  String _status = 'Recherche de la commande...';
  int _currentStep = 1;

  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _livreurData;
  RealtimeChannel? _livreurChannel;

  @override
  void initState() {
    super.initState();
    _fetchGpsLocation(); // GPS en parallèle (fallback)
    _fetchOrderData();   // Coords réelles depuis la BDD
  }

  @override
  void dispose() {
    _livreurChannel?.unsubscribe();
    super.dispose();
  }

  /// Récupère la position GPS du téléphone comme fallback
  Future<void> _fetchGpsLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _gpsPos = LatLng(position.latitude, position.longitude);
          // Si pas encore de position client depuis la BDD, utiliser le GPS
          _clientPos ??= _gpsPos;
        });
        _fitBounds();
      }
    } catch (_) {}
  }

  /// Centre la carte pour montrer les deux marqueurs (client + business)
  void _fitBounds() {
    final client = _clientPos;
    final biz    = _businessPos;
    if (client == null) return;

    if (biz == null) {
      // Seulement le client — zoom standard
      _mapController.move(client, 15.0);
      return;
    }

    // Calculer le centre des deux points
    final centerLat = (client.latitude  + biz.latitude)  / 2;
    final centerLng = (client.longitude + biz.longitude) / 2;

    // Distance → zoom adaptatif
    final distance = const Distance().as(LengthUnit.Kilometer, client, biz);
    double zoom;
    if (distance < 0.5)       zoom = 16.0;
    else if (distance < 1.5)  zoom = 15.0;
    else if (distance < 3)    zoom = 14.0;
    else if (distance < 8)    zoom = 13.0;
    else if (distance < 20)   zoom = 12.0;
    else                      zoom = 11.0;

    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  Future<void> _fetchOrderData() async {
    try {
      final supabase = Supabase.instance.client;
      final authProvider = context.read<AuthProvider>();
      final clientId = authProvider.roleId;

      Map<String, dynamic>? data;

      // ─── Requête principale : commande + adresse client + timeline ───────
      const selectQuery = '''
        *,
        adresse(id_adresse, latitude, longitude, ville),
        timeline(*, livreur(*, app_user(*)))
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

        // ── 1. Coordonnées du CLIENT depuis commande.adresse ──────────────
        LatLng? clientLatLng;
        final adresseData = data['adresse'];
        if (adresseData is Map) {
          final lat = double.tryParse(adresseData['latitude']?.toString() ?? '');
          final lng = double.tryParse(adresseData['longitude']?.toString() ?? '');
          if (lat != null && lng != null) clientLatLng = LatLng(lat, lng);
        }

        // ── 2. Coordonnées du BUSINESS via ligne_commande → produit → business
        //       → app_user → user_adresse → adresse ─────────────────────────
        LatLng? businessLatLng;
        String businessName = 'Commerce';
        try {
          // Stratégie A : id_business direct sur la commande (si colonne existe)
          int? bizId;
          if (data['id_business'] != null) {
            bizId = int.tryParse(data['id_business'].toString());
          }

          // Stratégie B : via ligne_commande → produit
          if (bizId == null) {
            final lines = await supabase
                .from('ligne_commande')
                .select('id_produit, produit(id_business)')
                .eq('id_commande', orderId)
                .limit(1);
            if (lines.isNotEmpty) {
              final produit = lines.first['produit'];
              if (produit is Map) {
                bizId = int.tryParse(produit['id_business']?.toString() ?? '');
              }
            }
          }

          // Récupère le business avec son adresse
          if (bizId != null) {
            final bizResp = await supabase
                .from('business')
                .select('''
                  id_business,
                  app_user(
                    nom,
                    user_adresse(
                      is_default,
                      adresse(latitude, longitude, ville)
                    )
                  )
                ''')
                .eq('id_business', bizId)
                .maybeSingle();

            if (bizResp != null) {
              final appUser = bizResp['app_user'];
              if (appUser is Map) {
                businessName = appUser['nom']?.toString() ?? 'Commerce';
                final userAdresses = appUser['user_adresse'] as List? ?? [];
                Map<String, dynamic>? bestAdresse;
                for (final ua in userAdresses) {
                  if (ua is Map) {
                    if (ua['is_default'] == true) {
                      bestAdresse = ua['adresse'] as Map<String, dynamic>?;
                      break;
                    }
                    bestAdresse ??= ua['adresse'] as Map<String, dynamic>?;
                  }
                }
                if (bestAdresse != null) {
                  final lat = double.tryParse(bestAdresse['latitude']?.toString() ?? '');
                  final lng = double.tryParse(bestAdresse['longitude']?.toString() ?? '');
                  if (lat != null && lng != null) {
                    businessLatLng = LatLng(lat, lng);
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Business coords fetch error: $e');
        }

        // ── 3. Position du LIVREUR depuis timeline.position_order ─────────
        LatLng? riderLatLng;
        final rawTimeline = data['timeline'];
        final timeline = (rawTimeline is List) ? rawTimeline : [];
        Map<String, dynamic>? livreurData;
        Map<String, dynamic>? lastTimeline;
        for (final t in timeline.reversed) {
          if (t is Map<String, dynamic>) {
            lastTimeline ??= t;
            if (t['livreur'] != null && livreurData == null) {
              livreurData = t['livreur'] as Map<String, dynamic>?;
            }
          }
        }
        if (lastTimeline != null) {
          final posOrder = lastTimeline['position_order'];
          if (posOrder is Map) {
            final lat = double.tryParse(
                posOrder['latitude']?.toString() ?? posOrder['lat']?.toString() ?? '');
            final lng = double.tryParse(
                posOrder['longitude']?.toString() ?? posOrder['lng']?.toString() ?? '');
            if (lat != null && lng != null) riderLatLng = LatLng(lat, lng);
          }
        }

        // ── 4. Statut ──────────────────────────────────────────────────────
        final status = data['statut_commande'] as String? ?? '';
        int step = 1;
        String statusText = 'Commande en attente';
        if (status == 'confirmee')         { step = 1; statusText = 'Commande confirmée'; }
        else if (status == 'preparee')     { step = 2; statusText = 'Le commerçant prépare votre commande'; }
        else if (status == 'en_livraison') { step = 3; statusText = 'Le livreur est en route !'; }
        else if (status == 'livree')       { step = 3; statusText = 'Votre commande est arrivée ! Merci de nous avoir choisis.'; }

        if (mounted) {
          setState(() {
            _orderData    = data;
            _livreurData  = livreurData;
            _clientPos    = clientLatLng ?? _gpsPos;
            _businessPos  = businessLatLng;
            _riderPos     = riderLatLng;
            _businessName = businessName;
            _currentStep  = step;
            _status       = statusText;
            _isLoading    = false;
          });
          _fitBounds();
        }

      } else if (mounted) {
        setState(() {
          _status    = 'Aucune commande active trouvée';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_fetchOrderData error: $e');
      if (mounted) {
        setState(() {
          _status    = 'Erreur de chargement';
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
    final clientPos  = _clientPos;
    final businessPos = _businessPos;
    final riderPos   = _riderPos;

    // Centre initial : client ou Tétouan par défaut
    final initialCenter = clientPos ?? const LatLng(35.5750, -5.3720);

    // Polyligne dashed entre client et business
    final polylinePoints = [
      if (clientPos != null)   clientPos,
      if (businessPos != null) businessPos,
    ];

    return ExcludeSemantics(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.livraison.app.frontend',
          ),

          // ── Polyligne client ↔ business ──────────────────────────────────
          if (polylinePoints.length == 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinePoints,
                  strokeWidth: 3.0,
                  color: AppColors.primary.withOpacity(0.4),
                  // strokeCap: StrokeCap.round, // uncomment if flutter_map supports it
                ),
              ],
            ),

          MarkerLayer(
            markers: [
              // ── Marqueur CLIENT ─────────────────────────────────────────
              if (clientPos != null)
                Marker(
                  point: clientPos,
                  width: 50,
                  height: 50,
                  child: Tooltip(
                    message: 'Votre position',
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                ),

              // ── Marqueur BUSINESS ────────────────────────────────────────
              if (businessPos != null)
                Marker(
                  point: businessPos,
                  width: 80,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _businessName.length > 12 ? '${_businessName.substring(0, 10)}…' : _businessName,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.store, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),

              // ── Marqueur LIVREUR ─────────────────────────────────────────
              if (riderPos != null && _livreurData != null)
                Marker(
                  point: riderPos,
                  width: 55,
                  height: 55,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.delivery_dining, color: AppColors.primary, size: 28),
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
        child: SingleChildScrollView(
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
                    child: Icon(
                      _currentStep == 3 && _status.contains('arrivée') 
                        ? Icons.check_circle_outline 
                        : Icons.timer, 
                      color: AppColors.primary, 
                      size: 28
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _status,
                          style: const TextStyle(
                            fontSize: 16, // Légèrement réduit pour éviter l'overflow
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (_orderData != null && _currentStep < 3)
                          const Text(
                            'Arrivée prévue dans environ 15 min',
                            style: TextStyle(
                                color: AppColors.mutedForeground, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_orderData != null) ...[
                const SizedBox(height: 16),
                _buildStatusTimeline(),
              ],
              const SizedBox(height: 12),
              // On affiche l'info de chargement seulement si on n'a pas encore de livreur
              if (_livreurData == null)
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
                           'Dès que le commerçant prépare votre colis, un livreur est assigné.',
                           style: TextStyle(fontSize: 11, color: AppColors.primary),
                         ),
                       ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondary,
                    child: Text(_livreurData != null ? '🛵' : '👤'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          livreurName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          livreurRating,
                          style: const TextStyle(
                              color: AppColors.mutedForeground, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_livreurData != null)
                    _ContactAction(icon: Icons.phone_outlined, onTap: _callLivreur),
                ],
              ),
              if (_orderData?['statut_commande'] == 'livree') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Fermer le suivi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
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
