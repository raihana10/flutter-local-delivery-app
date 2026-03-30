import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/product_provider.dart';
import '../../../data/models/business_model.dart';
import '../../../core/providers/business_data_provider.dart';
import '../../../core/providers/auth_provider.dart';

import '../../widgets/product_image_placeholder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'views/business_stats_view.dart';
import 'views/business_notifications_view.dart';
import 'views/business_profile_view.dart';
import '../shared/in_app_call_screen.dart';

enum BusinessScreen {
  dashboard,
  catalog,
  history,
  addProduct,
  importSheet,
  orderDetail,
  editProduct,
  stats,
  notifications,
  profile,
  promotions,
  addPromotion
}

class BusinessMainScreen extends StatefulWidget {
  final int? idBusiness;
  const BusinessMainScreen({super.key, this.idBusiness});

  @override
  State<BusinessMainScreen> createState() => _BusinessMainScreenState();
}

class _BusinessMainScreenState extends State<BusinessMainScreen> {
  BusinessScreen _currentScreen = BusinessScreen.dashboard;
  int _editingIndex = -1;
  int? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bdp = context.read<BusinessDataProvider>();
      await bdp.loadIdBusinessPk();
      if (!mounted) return;
      if (bdp.idBusinessPk != null) {
        context.read<ProductProvider>().fetchProductsByBusiness(bdp.idBusinessPk!);
      }
      await bdp.fetchAll();
    });
  }

  void _setScreen(BusinessScreen screen, {int? index, int? orderId}) {
    setState(() {
      _currentScreen = screen;
      if (index != null) _editingIndex = index;
      if (orderId != null) _selectedOrderId = orderId;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _getNavIndex(),
          onTap: (index) {
            if (index == 0) _setScreen(BusinessScreen.dashboard);
            if (index == 1) _setScreen(BusinessScreen.catalog);
            if (index == 2) _setScreen(BusinessScreen.history);
            if (index == 3) _setScreen(BusinessScreen.stats);
            if (index == 4) _setScreen(BusinessScreen.profile);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedForeground,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2), label: 'Catalogue'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'Historique'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  int _getNavIndex() {
    switch (_currentScreen) {
      case BusinessScreen.catalog:
      case BusinessScreen.addProduct:
      case BusinessScreen.importSheet:
      case BusinessScreen.editProduct:
      case BusinessScreen.promotions:
      case BusinessScreen.addPromotion:
        return 1;
      case BusinessScreen.history:
        return 2;
      case BusinessScreen.stats:
        return 3;
      case BusinessScreen.profile:
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case BusinessScreen.dashboard:
        return _DashboardView(
          onNavigate: _setScreen,
        );
      case BusinessScreen.catalog:
        return _CatalogView(onNavigate: _setScreen);
      case BusinessScreen.history:
        return _HistoryView(onNavigate: _setScreen);
      case BusinessScreen.addProduct:
        return _AddProductView(onNavigate: _setScreen);
      case BusinessScreen.importSheet:
        return _ImportSheetView(onNavigate: _setScreen);
      case BusinessScreen.orderDetail:
        return _OrderDetailView(
            onNavigate: _setScreen, orderId: _selectedOrderId);
      case BusinessScreen.editProduct:
        return _EditProductView(index: _editingIndex, onNavigate: _setScreen);
      case BusinessScreen.promotions:
        return _PromotionsView(onNavigate: _setScreen);
      case BusinessScreen.addPromotion:
        return _AddPromotionView(onNavigate: _setScreen);
      case BusinessScreen.stats:
        return BusinessStatsView(onNavigate: _setScreen);
      case BusinessScreen.notifications:
        return BusinessNotificationsView(onNavigate: _setScreen);
      case BusinessScreen.profile:
        return BusinessProfileView(onNavigate: _setScreen);
    }
  }
}

// ============ UTILS ============
String _formatTimeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} h';
  } else {
    return '${diff.inDays} j';
  }
}

// ============ DASHBOARD VIEW ============
class _DashboardView extends StatefulWidget {
  final Function(BusinessScreen, {int? index, int? orderId}) onNavigate;

  const _DashboardView({
    required this.onNavigate,
    super.key,
  });

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  bool _isSwitching = false;

  @override
  Widget build(BuildContext context) {
    final businessData = context.watch<BusinessDataProvider>();
    
    final stats = businessData.stats;
    final profile = businessData.profile;
    
    final allOrders = (stats['recent_orders'] ?? stats['commandes_recentes'] ?? []) as List<dynamic>;
    
    // Filter orders: last 24h & not delivered
    final now = DateTime.now();
    final ordersList = allOrders.where((o) {
      final createdAt = DateTime.tryParse(o['created_at'].toString());
      final statut = o['statut_commande'] as String? ?? '';
      if (createdAt == null) return false;
      final diff = now.difference(createdAt);
      return diff.inHours < 24 && statut != 'livree';
    }).toList();

    final businessName = profile['app_user']?['nom'] ?? 'Business Name';
    final businessType = profile['type_business'] ?? 'Type de Business';

    final revenus = stats['revenus_totaux']?.toString() ?? '0';
    final nbCommandes = allOrders.length.toString();
    final rating = stats['note_moyenne']?.toString() ?? '4.8';
    
    final bool isOpen = profile['is_open'] == true;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.store,
                          color: AppColors.amber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          Text(
                            businessType,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSwitching ? null : () async {
                        setState(() => _isSwitching = true);
                        final success = await businessData.updateProfile({'is_open': !isOpen});
                        setState(() => _isSwitching = false);
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour.')));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.amber
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isSwitching 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: AppColors.forest, strokeWidth: 2))
                            : Text(
                                isOpen ? 'Ouvert' : 'Fermé',
                                style: TextStyle(
                                  color: isOpen ? AppColors.forest : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onNavigate(BusinessScreen.notifications),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(LucideIcons.bell,
                                color: Colors.white, size: 20),
                            if (businessData.unreadNotificationsCount > 0)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${businessData.unreadNotificationsCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'profile') {
                          widget.onNavigate(BusinessScreen.profile);
                        } else if (value == 'logout') {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/');
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(LucideIcons.user,
                                  color: AppColors.forest, size: 20),
                              SizedBox(width: 8),
                              Text('Profil'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Déconnexion'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // KPI Grid
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    _buildKPI(
                        'Commandes', nbCommandes, LucideIcons.shoppingBag),
                    const SizedBox(width: 12),
                    _buildKPI('CA (MAD)', revenus, LucideIcons.trendingUp),
                    const SizedBox(width: 12),
                    _buildKPI('Note', '$rating ⭐', LucideIcons.star),
                  ],
                ),
              ),              // Orders List
              if (ordersList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Center(
                    child: Text(
                      "Aucune commande active.",
                      style: TextStyle(color: AppColors.mutedForeground),
                    ),
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ordersList.length,
                  itemBuilder: (context, index) {
                    final o = ordersList[index];
                    return _buildOrderCard(o);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStatusButtons(int commandeId, String statut) {
    final provider = context.read<BusinessDataProvider>();
    if (statut == 'confirmee') {
      return [
        _buildOrderButton('Commande prête (Préparée)', AppColors.forest, Colors.white, () {
          provider.updateOrderStatus(commandeId.toString(), 'preparee');
        }),
      ];
    } else if (statut == 'preparee') {
      return [
        _buildOrderButton('En attente du livreur', Colors.grey.shade200, Colors.grey.shade700, null),
      ];
    } else if (statut == 'en_livraison') {
      return [
        _buildOrderButton('En cours de livraison', AppColors.amber, Colors.white, null),
      ];
    } else if (statut == 'livree') {
      return [
        _buildOrderButton('Livrée', AppColors.sage, Colors.white, null),
      ];
    } else {
      return [
        Expanded(
            child: Text(statut.toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedForeground,
                    fontSize: 12))),
      ];
    }
  }

  Widget _buildKPI(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.forest)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton(
      String text, Color bg, Color textCol, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
                color: textCol, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(String text, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.cardShadow,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.forest),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic o) {
    final commandeId = o['id_commande'];
    final statut = o['statut_commande'] as String? ?? '';
    final timeAgo = _formatTimeAgo(DateTime.tryParse(o['created_at'].toString()));
    
    final clientName = o['client_nom'] ?? o['client_name'] ?? 'Client #$commandeId';
    final itemsCount = o['items'] ?? o['nb_articles'] ?? '1+';
    final total = o['prix_total'] ?? o['total'] ?? 0.0;
    
    return GestureDetector(
      onTap: () => widget.onNavigate(BusinessScreen.orderDetail, orderId: commandeId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('#$commandeId', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest)),
                    const SizedBox(width: 8),
                    Text(clientName, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  ],
                ),
                Text(timeAgo, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text('$itemsCount articles • $total MAD', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: _buildStatusButtons(commandeId, statut)),
          ],
        ),
      ),
    );
  }
}

// ============ CATALOG VIEW ============
class _CatalogView extends StatelessWidget {
  final Function(BusinessScreen, {int? index}) onNavigate;

  const _CatalogView({required this.onNavigate});

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajouter un produit',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.forest)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.plus, color: AppColors.forest),
              ),
              title: const Text('Ajout manuel',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Remplir le formulaire complet'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(BusinessScreen.addProduct);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.fileSpreadsheet,
                    color: AppColors.forest),
              ),
              title: const Text('Import par fichier',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Importer via CSV ou Excel'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(BusinessScreen.importSheet);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.ticket, color: AppColors.forest),
              ),
              title: const Text('Ajouter une promotion',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Annoncer une offre ou une réduction'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(BusinessScreen.addPromotion);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onNavigate(BusinessScreen.dashboard),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          color: AppColors.warmWhite, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.arrowLeft,
                          color: AppColors.forest, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Catalogue',
                      style: TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Grid
            Expanded(
              child: Consumer2<ProductProvider, BusinessDataProvider>(
                builder: (context, provider, businessData, child) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: provider.businessProducts.length,
                    itemBuilder: (context, index) {
                      final item = provider.businessProducts[index];
                      final businessId = businessData.idBusinessPk;
                      final isAvailable = item.isAvailable;

                      return Opacity(
                        opacity: isAvailable ? 1.0 : 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.white
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow:
                                isAvailable ? AppColors.cardShadow : null,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Stack(
                                  children: [
                                    item.image != null && item.image!.startsWith('http')
                                        ? Stack(
                                            children: [
                                              // Blurred background for vertical images
                                              Positioned.fill(
                                                child: CachedNetworkImage(
                                                  imageUrl: item.image!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                  child: Container(color: Colors.white.withOpacity(0.2)),
                                                ),
                                              ),
                                              // Clear foreground image
                                              Center(
                                                child: CachedNetworkImage(
                                                  imageUrl: item.image!,
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  placeholder: (context, url) => Shimmer.fromColors(
                                                    baseColor: Colors.grey[300]!,
                                                    highlightColor: Colors.grey[100]!,
                                                    child: Container(color: Colors.white),
                                                  ),
                                                  errorWidget: (context, url, error) => ProductImagePlaceholder(
                                                    type: item.type,
                                                    borderRadius: BorderRadius.zero,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : ProductImagePlaceholder(
                                            type: item.type,
                                            borderRadius: BorderRadius.zero,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                    if (!isAvailable)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text('MASQUÉ',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nom,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isAvailable ? AppColors.forest : Colors.grey)),
                                    Text('${item.prix} MAD',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isAvailable ? AppColors.gold : Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () => onNavigate(
                                              BusinessScreen.editProduct,
                                              index: index),
                                          child: Icon(LucideIcons.pencil,
                                              color: isAvailable ? AppColors.gold : Colors.grey, size: 16),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (businessId != null) {
                                              provider
                                                  .toggleProductAvailability(
                                                      item);
                                            }
                                          },
                                          child: Icon(
                                              isAvailable
                                                  ? LucideIcons.eyeOff
                                                  : LucideIcons.eye,
                                              color: isAvailable
                                                  ? AppColors.mutedForeground
                                                  : AppColors.forest,
                                              size: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),

        // FAB
        Positioned(
          bottom: 40,
          right: 24,
          child: GestureDetector(
            onTap: () => _showAddOptions(context),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                boxShadow: AppColors.elevatedShadow,
              ),
              child: const Icon(LucideIcons.plus,
                  color: AppColors.forest, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

// ============ IMPORT SHEET VIEW ============
class _ImportSheetView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;
  const _ImportSheetView({required this.onNavigate});

  @override
  State<_ImportSheetView> createState() => _ImportSheetViewState();
}

class _ImportSheetViewState extends State<_ImportSheetView> {
  List<Produit> _previewItems = [];
  bool _isLoading = false;
  String? _fileName;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
        _fileName = result.files.single.name;
      });

      final file = File(result.files.single.path!);
      final ext = result.files.single.extension!;

      final items = await context.read<ProductProvider>().parseFile(file, ext);

      setState(() {
        _previewItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onNavigate(BusinessScreen.catalog),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.warmWhite, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.arrowLeft,
                      color: AppColors.forest, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Import par fichier',
                  style: TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _previewItems.isEmpty
                ? _buildUploadStep()
                : _buildPreviewStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: AppColors.warmWhite,
                borderRadius: BorderRadius.circular(32)),
            child: const Icon(LucideIcons.fileSpreadsheet,
                size: 48, color: AppColors.forest),
          ),
          const SizedBox(height: 24),
          const Text('Sélectionnez un fichier',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('CSV ou Excel (.xlsx)',
              style: TextStyle(color: AppColors.mutedForeground)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _pickFile,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Choisir un fichier'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fichier : $_fileName',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.gold)),
        const SizedBox(height: 8),
        Text('${_previewItems.length} produits extraits',
            style: const TextStyle(
                color: AppColors.mutedForeground, fontSize: 12)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _previewItems.length,
            itemBuilder: (context, index) {
              final item = _previewItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nom,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(item.type,
                              style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${item.prix} MAD',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            final bdp = context.read<BusinessDataProvider>();
            await bdp.loadIdBusinessPk();
            final businessId = bdp.idBusinessPk;
            if (businessId != null) {
              await context
                  .read<ProductProvider>()
                  .addBatch(_previewItems, businessId);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '${_previewItems.length} produits importés avec succès !'),
                    backgroundColor: AppColors.online),
              );
              widget.onNavigate(BusinessScreen.catalog);
            }
          },
          child: const Text('Importer tout'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ============ ADD PRODUCT VIEW ============
class _AddProductView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;
  const _AddProductView({required this.onNavigate});

  @override
  State<_AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<_AddProductView> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _category = 'meal';
  bool _isDispo = true;
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onNavigate(BusinessScreen.catalog),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.warmWhite, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.forest, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Nouveau produit',
                    style: TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Premium Image Selector
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.warmWhite,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forest.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedImage != null
                              ? (kIsWeb 
                                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                              : Container(
                                  color: AppColors.warmWhite,
                                  child: Icon(LucideIcons.image, 
                                    color: AppColors.forest.withOpacity(0.3), 
                                    size: 40
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildField('Nom du produit', 'Ex: Tajine Berbère',
                    controller: _nameController),
                const SizedBox(height: 16),
                _buildField('Description', 'Détails du produit...',
                    lines: 2, controller: _descController),
                const SizedBox(height: 16),
                _buildField('Prix (MAD)', '0.00',
                    keyboardType: TextInputType.number,
                    controller: _priceController),
                const SizedBox(height: 16),
                _buildCategorySelector(_category, (v) => setState(() => _category = v)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disponible',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest)),
                    Switch(
                      value: _isDispo,
                      onChanged: (v) => setState(() => _isDispo = v),
                      activeColor: AppColors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : () async {
                      final bdp = context.read<BusinessDataProvider>();
                      await bdp.loadIdBusinessPk();
                      final businessId = bdp.idBusinessPk;
                      if (businessId == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Commerce introuvable. Réessayez dans un instant ou revenez au tableau admin.',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom et prix requis')));
                        return;
                      }

                      setState(() => _isUploading = true);
                      
                      try {
                        String? imageUrl;
                        if (_selectedImage != null) {
                          final provider = context.read<ProductProvider>();
                          imageUrl = await provider.uploadImage(_selectedImage!);
                          if (imageUrl == null) {
                            throw Exception("L'upload de l'image a échoué. Vérifiez que le bucket 'product-image' existe dans Supabase.");
                          }
                        }

                        final p = Produit(
                          id: 0,
                          idBusiness: businessId,
                          nom: _nameController.text,
                          description: _descController.text,
                          prix: double.tryParse(_priceController.text) ?? 0.0,
                          type: _category,
                          image: imageUrl,
                        );
                        
                        await context.read<ProductProvider>().addProduct(p);
                        
                        if (mounted) {
                          widget.onNavigate(BusinessScreen.catalog);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isUploading = false);
                        }
                      }
                    },
                    child: _isUploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Enregistrer le produit'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String placeholder,
      {int lines = 1,
      TextInputType? keyboardType,
      TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.forest)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle:
                const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            filled: true,
            fillColor: AppColors.warmWhite,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(String current, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catégorie de produit',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.forest)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: current,
          items: const [
            DropdownMenuItem(value: 'meal', child: Text('Restaurant (Plat)')),
            DropdownMenuItem(
                value: 'grocery', child: Text('Supermarché (Courses)')),
            DropdownMenuItem(
                value: 'pharmacy', child: Text('Pharmacie (Médicament)')),
          ],
          onChanged: (v) => onChanged(v ?? 'meal'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.warmWhite,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }
}

// ============ EDIT PRODUCT VIEW ============
class _EditProductView extends StatefulWidget {
  final int index;
  final Function(BusinessScreen) onNavigate;
  const _EditProductView({required this.index, required this.onNavigate});

  @override
  State<_EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<_EditProductView> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late bool _isDispo;
  late String _category;
  XFile? _selectedImage;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProductProvider>().businessProducts[widget.index];
    _nameController = TextEditingController(text: p.nom);
    _descController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.prix.toString());
    _isDispo = true;
    _category = p.type ?? 'meal';
    _currentImageUrl = p.image;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onNavigate(BusinessScreen.catalog),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.warmWhite, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.forest, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Modifier le produit',
                    style: TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Premium Image Selector (Edit mode)
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.warmWhite,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forest.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedImage != null
                              ? (kIsWeb 
                                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                              : (_currentImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => const Icon(LucideIcons.imageOff),
                                    )
                                  : Container(
                                      color: AppColors.warmWhite,
                                      child: Icon(LucideIcons.image, 
                                        color: AppColors.forest.withOpacity(0.3), 
                                        size: 40
                                      ),
                                    )),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildField('Nom du produit', 'Ex: Tajine Berbère',
                    controller: _nameController),
                const SizedBox(height: 16),
                _buildField('Description', 'Détails du produit...',
                    lines: 2, controller: _descController),
                const SizedBox(height: 16),
                _buildField('Prix (MAD)', '0.00',
                    keyboardType: TextInputType.number,
                    controller: _priceController),
                const SizedBox(height: 16),
                _buildCategorySelector(_category, (v) => setState(() => _category = v)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disponible',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest)),
                    Switch(
                      value: _isDispo,
                      onChanged: (v) => setState(() => _isDispo = v),
                      activeColor: AppColors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : () async {
                      setState(() => _isUploading = true);
                      try {
                        final provider = context.read<ProductProvider>();
                        final old = provider.businessProducts[widget.index];
                        
                        String? imageUrl = old.image;
                        if (_selectedImage != null) {
                          imageUrl = await provider.uploadImage(_selectedImage!);
                          if (imageUrl == null) {
                            throw Exception("L'upload de l'image a échoué. Vérifiez que le bucket 'product-image' existe dans Supabase.");
                          }
                        }

                        final p = Produit(
                          id: old.id,
                          idBusiness: old.idBusiness,
                          nom: _nameController.text,
                          description: _descController.text,
                          prix: double.tryParse(_priceController.text) ?? 0.0,
                          type: _category,
                          image: imageUrl,
                        );
                        
                        await provider.updateProduct(p);
                        
                        if (mounted) {
                          widget.onNavigate(BusinessScreen.catalog);
                        }
                      } catch (e) {
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                         }
                      } finally {
                        if (mounted) {
                          setState(() => _isUploading = false);
                        }
                      }
                    },
                    child: _isUploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enregistrer les modifications'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String placeholder,
      {int lines = 1,
      TextInputType? keyboardType,
      TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.forest)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle:
                const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            filled: true,
            fillColor: AppColors.warmWhite,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(String current, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catégorie de produit',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.forest)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: current,
          items: const [
            DropdownMenuItem(value: 'meal', child: Text('Restaurant (Plat)')),
            DropdownMenuItem(
                value: 'grocery', child: Text('Supermarché (Courses)')),
            DropdownMenuItem(
                value: 'pharmacy', child: Text('Pharmacie (Médicament)')),
          ],
          onChanged: (v) => onChanged(v ?? 'meal'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.warmWhite,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }
}

// ============ ORDER DETAIL VIEW ============
class _OrderDetailView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;
  final int? orderId;

  const _OrderDetailView({required this.onNavigate, this.orderId});

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<_OrderDetailView> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (widget.orderId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final data = await context
        .read<BusinessDataProvider>()
        .fetchOrderDetails(widget.orderId!);
    setState(() {
      _orderData = data;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    if (widget.orderId != null) {
      await context
          .read<BusinessDataProvider>()
          .updateOrderStatus(widget.orderId!.toString(), newStatus);
      _fetchDetails();
    }
  }

  void _launchPhoneCall(String phoneNumber, String name, String role) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch phone call to $phoneNumber');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lancer l\'appel.')),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf(Map<String, dynamic> order, List<dynamic> lines) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('FACTURE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Commande #${order['id_commande']}'),
              pw.Text('Date: ${DateTime.now().toLocal().toString().split('.')[0]}'),
              pw.Divider(),
              ...lines.map((l) {
                 final qty = l['quantite'];
                 final price = l['total_ligne'];
                 final prodName = l['produit'] != null ? l['produit']['nom_produit'] : 'Produit';
                 return pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                     pw.Expanded(child: pw.Text('$qty x $prodName', style: const pw.TextStyle(fontSize: 10))),
                     pw.Text('$price MAD', style: const pw.TextStyle(fontSize: 10)),
                   ],
                 );
              }).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('${order['prix_total']} MAD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Merci pour votre commande !', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
            ]
          );
        }
      )
    );

    return pdf.save();
  }

  void _showReceiptPreview(Map<String, dynamic> order, List<dynamic> lines) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Aperçu du reçu'),
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
        ),
        body: PdfPreview(
          build: (format) => _generatePdf(order, lines),
          allowSharing: true,
          allowPrinting: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orderData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Commande introuvable.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.onNavigate(BusinessScreen.dashboard),
              child: const Text('Retour'),
            )
          ],
        ),
      );
    }

    final order = _orderData!['order'];
    final lines = _orderData!['lines'] as List<dynamic>;

    final statut = order['statut_commande'] ?? '';
    final clientName = order['client']?['app_user']?['nom'] ?? 'Client Inconnu';
    final clientPhone = order['client']?['app_user']?['num_tl'] ?? '';
    final addressLine = order['adresse']?['ville'] ?? 'Adresse non spécifiée';
    final total = order['prix_total']?.toString() ?? '0';

    final timeline = order['timeline'] is List
        ? (order['timeline'] as List).lastOrNull
        : order['timeline'];
    final livreur = timeline?['livreur'];
    final livreurName = livreur?['app_user']?['nom'] ?? 'Aucun livreur';
    final livreurPhone = livreur?['app_user']?['num_tl'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onNavigate(BusinessScreen.dashboard),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.warmWhite, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.forest, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commande #${widget.orderId}',
                        style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text(statut.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.mutedForeground, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$total MAD',
                      style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.cardShadow),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppColors.forest.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(LucideIcons.user,
                            color: AppColors.forest),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(clientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.forest)),
                            Text(addressLine,
                                style: const TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      if (clientPhone.isNotEmpty)
                        GestureDetector(
                          onTap: () => _launchPhoneCall(clientPhone, clientName, 'Client'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.sage.withOpacity(0.15),
                                shape: BoxShape.circle),
                            child: const Icon(LucideIcons.phone,
                                color: AppColors.sage, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Driver Info (if applicable)
                if (livreur != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppColors.cardShadow),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.2),
                              shape: BoxShape.circle),
                          child: const Icon(LucideIcons.bike,
                              color: AppColors.amber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(livreurName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.forest)),
                              const Text('Livreur assigné',
                                  style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        if (livreurPhone.isNotEmpty)
                          GestureDetector(
                            onTap: () => _launchPhoneCall(livreurPhone, livreurName, 'Livreur'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: AppColors.sage.withOpacity(0.15),
                                  shape: BoxShape.circle),
                              child: const Icon(LucideIcons.phone,
                                  color: AppColors.sage, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Order Lines
                ...lines.map((l) {
                  final qty = l['quantite'];
                  final price = l['total_ligne'];
                  final prodName = l['produit'] != null
                      ? l['produit']['nom_produit']
                      : 'Produit inconnu';
                  return _buildOrderItem(qty, prodName, price.toString());
                }).toList(),

                const SizedBox(height: 20),

                // Price Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow),
                  child: Builder(builder: (context) {
                    final subTotal = lines.fold<double>(
                      0.0,
                      (sum, l) => sum + ((l['total_ligne'] as num?)?.toDouble() ?? 0.0),
                    );
                    final totalDouble = double.tryParse(total) ?? 0.0;
                    final deliveryFee = totalDouble - subTotal;

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sous-total',
                                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                            Text('${subTotal.toStringAsFixed(1)} MAD',
                                style: const TextStyle(color: AppColors.forest, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Frais de livraison',
                                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                            Text('${deliveryFee.toStringAsFixed(2)} MAD',
                                style: const TextStyle(color: AppColors.forest, fontSize: 13)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: AppColors.border),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.forest)),
                            Text('$total MAD',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.gold)),
                          ],
                        ),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Action Buttons based on status
                if (statut == 'confirmee') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest),
                          onPressed: () => _updateStatus('preparee'),
                          child: const Text('Commande prête (Préparée)'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Text('Statut actuel: ${statut.toUpperCase()}',
                        style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.bold)),
                  ),
                ],

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _showReceiptPreview(order, lines),
                  icon: const Icon(LucideIcons.download, size: 16),
                  label: const Text('Télécharger le reçu'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(int qty, String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: AppColors.amber, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text('$qty',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.forest)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w500,
                      fontSize: 14))),
          Text('$price MAD',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ============ UTILS ============
class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _controller,
        child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.destructive, shape: BoxShape.circle)));
  }
}

// ============ HISTORY VIEW ============
class _HistoryView extends StatelessWidget {
  final Function(BusinessScreen, {int? index, int? orderId}) onNavigate;

  const _HistoryView({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final businessData = context.watch<BusinessDataProvider>();
    final ordersList = (businessData.stats['recent_orders'] ?? businessData.stats['commandes_recentes'] ?? []) as List<dynamic>;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          decoration: const BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),
              Text(
                'Toutes vos commandes passées',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: ordersList.isEmpty
              ? const Center(child: Text('Aucune commande dans l\'historique'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: ordersList.length,
                  itemBuilder: (context, index) {
                    final o = ordersList[index];
                    final commandeId = o['id_commande'];
                    final statut = o['statut_commande'] as String? ?? '';
                    final timeAgo = _formatTimeAgo(
                        DateTime.tryParse(o['created_at'].toString()));

                    return GestureDetector(
                      onTap: () => onNavigate(BusinessScreen.orderDetail,
                          orderId: commandeId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statut == 'livree'
                                    ? AppColors.forest.withOpacity(0.1)
                                    : AppColors.amber.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                statut == 'livree'
                                    ? LucideIcons.check
                                    : LucideIcons.clock,
                                color: statut == 'livree'
                                    ? AppColors.forest
                                    : AppColors.amber,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('#$commandeId - ${o['client_nom'] ?? o['client_name'] ?? 'Client'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.forest)),
                                  Text('${o['prix_total'] ?? o['total'] ?? 0} MAD • $statut',
                                      style: const TextStyle(
                                          color: AppColors.mutedForeground,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(timeAgo,
                                style: const TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============ PROMOTIONS VIEW ============
class _PromotionsView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;
  const _PromotionsView({required this.onNavigate});

  @override
  State<_PromotionsView> createState() => _PromotionsViewState();
}

class _PromotionsViewState extends State<_PromotionsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bdp = context.read<BusinessDataProvider>();
      await bdp.loadIdBusinessPk();
      final bid = bdp.idBusinessPk;
      if (bid != null && context.mounted) {
        context.read<ProductProvider>().fetchPromotionsByBusiness(bid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<BusinessDataProvider>().idBusinessPk;
    final provider = context.watch<ProductProvider>();
    final promos = provider.promotions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => widget.onNavigate(BusinessScreen.catalog),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.warmWhite, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.arrowLeft,
                      color: AppColors.forest, size: 20),
                ),
              ),
              const Text('Mes Promotions',
                  style: TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                      fontSize: 24)),
              IconButton(
                icon:
                    const Icon(LucideIcons.circlePlus, color: AppColors.forest),
                onPressed: () => widget.onNavigate(BusinessScreen.addPromotion),
              ),
            ],
          ),
        ),
        Expanded(
          child: promos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.ticket,
                          size: 64, color: AppColors.forest.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text('Aucune promotion active',
                          style: TextStyle(color: AppColors.mutedForeground)),
                      TextButton(
                          onPressed: () =>
                              widget.onNavigate(BusinessScreen.addPromotion),
                          child: const Text('Ajouter ma première promo')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final p = promos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(LucideIcons.ticket,
                              color: AppColors.amber),
                        ),
                        title: Text(p.produit?.nom ?? 'Promotion #${p.id}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.pourcentage.toInt()}% de réduction - Expire le ${p.dateFin.day}/${p.dateFin.month}'),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            if (businessId != null) {
                              provider.deletePromotion(p.id, businessId);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============ ADD PROMOTION VIEW ============
class _AddPromotionView extends StatefulWidget {
  final Function(BusinessScreen) onNavigate;
  const _AddPromotionView({required this.onNavigate});

  @override
  State<_AddPromotionView> createState() => _AddPromotionViewState();
}

class _AddPromotionViewState extends State<_AddPromotionView> {
  final List<int> _selectedProductIds = [];
  final _pourcentageController = TextEditingController();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  void _toggleProduct(int id) {
    setState(() {
      if (_selectedProductIds.contains(id)) {
        _selectedProductIds.remove(id);
      } else {
        _selectedProductIds.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bdp = context.read<BusinessDataProvider>();
      await bdp.loadIdBusinessPk();
      final bid = bdp.idBusinessPk;
      if (bid != null && context.mounted) {
        context.read<ProductProvider>().fetchProductsByBusiness(bid);
        context.read<ProductProvider>().fetchPromotionsByBusiness(bid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().businessProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onNavigate(BusinessScreen.promotions),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.warmWhite, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.forest, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Nouvelle Promotion',
                    style: TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sélectionner les produits',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final p = products[idx];
                      final isSelected = _selectedProductIds.contains(p.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleProduct(p.id),
                        title: Text(p.nom, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${p.prix} MAD', style: const TextStyle(fontSize: 12)),
                        activeColor: AppColors.forest,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pourcentage de réduction',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _pourcentageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ex: 20',
                    suffixText: '%',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Date de fin',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                        const Icon(LucideIcons.calendar, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _savePromotion,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Ajouter la promotion',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePromotion() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner au moins un produit')));
      return;
    }
    final int? pourcentage = int.tryParse(_pourcentageController.text);
    if (pourcentage == null || pourcentage <= 0 || pourcentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez saisir un pourcentage valide (1-100)')));
      return;
    }

    setState(() => _isLoading = true);

    final bdp = context.read<BusinessDataProvider>();
    await bdp.loadIdBusinessPk();
    final roleId = bdp.idBusinessPk;
    if (roleId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identifiant commerce introuvable.')),
        );
      }
      return;
    }

    final provider = context.read<ProductProvider>();
    final currentPromos = provider.promotions;
    bool allSuccess = true;
    int skipCount = 0;

    try {
      for (final pid in _selectedProductIds) {
        // Skip if this product ALREADY has an active promotion in memory
        if (currentPromos.any((p) => p.idProduit == pid)) {
          skipCount++;
          continue;
        }

        final promo = Promotion(
          id: 0,
          idProduit: pid,
          pourcentage: pourcentage.toDouble(),
          dateDebut: DateTime.now(),
          dateFin: _endDate,
        );
        final success = await provider.addPromotion(promo, roleId);
        if (!success) allSuccess = false;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        String msg = allSuccess ? 'Promotion(s) ajoutée(s) avec succès !' : 'Erreur lors de certains ajouts.';
        if (skipCount > 0) msg += ' ($skipCount déjà en promo)';
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        widget.onNavigate(BusinessScreen.promotions);
      }
    } catch (e) {
       if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')));
       }
    }
  }

  Widget _buildField(String label, String placeholder,
      {int lines = 1,
      TextInputType? keyboardType,
      TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.forest)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle:
                const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            filled: true,
            fillColor: AppColors.warmWhite,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
