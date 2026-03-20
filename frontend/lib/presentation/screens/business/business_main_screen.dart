import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import 'package:app/core/providers/auth_provider.dart';
import '../../../../models/business_product.dart';
import '../../../../providers/product_provider.dart';
import '../../../../core/providers/business_data_provider.dart';
import 'views/business_stats_view.dart';
import 'views/business_notifications_view.dart';
import 'views/business_profile_view.dart';

enum BusinessScreen {
  dashboard,
  catalog,
  addProduct,
  importSheet,
  orderDetail,
  editProduct,
  stats,
  notifications,
  profile
}

class BusinessMainScreen extends StatefulWidget {
  final int? idBusiness;
  const BusinessMainScreen({super.key, this.idBusiness});

  @override
  State<BusinessMainScreen> createState() => _BusinessMainScreenState();
}

class _BusinessMainScreenState extends State<BusinessMainScreen> {
  BusinessScreen _currentScreen = BusinessScreen.dashboard;
  bool _isOpen = true; // Temporary mock, wait for data
  int _editingIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessDataProvider>().fetchAll();
    });
  }

  void _setScreen(BusinessScreen screen, {int? index}) {
    setState(() {
      _currentScreen = screen;
      if (index != null) _editingIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case BusinessScreen.dashboard:
        return _DashboardView(
          isOpen: _isOpen,
          onToggleOpen: () => setState(() => _isOpen = !_isOpen),
          onNavigate: _setScreen,
        );
      case BusinessScreen.catalog:
        return _CatalogView(onNavigate: _setScreen);
      case BusinessScreen.addProduct:
        return _AddProductView(onNavigate: _setScreen);
      case BusinessScreen.importSheet:
        return _ImportSheetView(onNavigate: _setScreen);
      case BusinessScreen.orderDetail:
        return _OrderDetailView(onNavigate: _setScreen);
      case BusinessScreen.editProduct:
        return _EditProductView(index: _editingIndex, onNavigate: _setScreen);
      case BusinessScreen.stats:
        return BusinessStatsView(onNavigate: _setScreen);
      case BusinessScreen.notifications:
        return BusinessNotificationsView(onNavigate: _setScreen);
      case BusinessScreen.profile:
        return BusinessProfileView(onNavigate: _setScreen);
    }
  }
}

// ============ DASHBOARD VIEW ============
class _DashboardView extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggleOpen;
  final Function(BusinessScreen, {int? index}) onNavigate;

  const _DashboardView({
    required this.isOpen,
    required this.onToggleOpen,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
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
                      child: const Icon(LucideIcons.utensils,
                          color: AppColors.amber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dar Zitoun',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          Text(
                            'Restaurant Marocain',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggleOpen,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.amber
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
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
                      onTap: () => onNavigate(BusinessScreen.notifications),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.bell,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'profile') {
                          onNavigate(BusinessScreen.profile);
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
                    _buildKPI('Commandes', '24', LucideIcons.shoppingBag),
                    const SizedBox(width: 12),
                    _buildKPI('CA (MAD)', '3,450', LucideIcons.trendingUp),
                    const SizedBox(width: 12),
                    _buildKPI('Note', '4.8 ⭐', LucideIcons.star),
                  ],
                ),
              ),

              // New Orders Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Nouvelles commandes',
                      style: TextStyle(
                          color: AppColors.forest, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _PulseIndicator(),
                  ],
                ),
              ),

              // Orders List
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                itemBuilder: (context, index) {
                  final orders = [
                    {
                      'id': '#1042',
                      'client': 'Alae B.',
                      'items': 3,
                      'time': '5 min'
                    },
                    {
                      'id': '#1043',
                      'client': 'Sara M.',
                      'items': 2,
                      'time': '2 min'
                    },
                  ];
                  final o = orders[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('${o['id']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.forest)),
                                const SizedBox(width: 8),
                                Text('${o['client']}',
                                    style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 12)),
                              ],
                            ),
                            Text('${o['time']}',
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${o['items']} articles',
                            style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildOrderButton(
                                'Accepter', AppColors.forest, Colors.white),
                            const SizedBox(width: 8),
                            _buildOrderButton(
                                'Préparer', AppColors.sage, Colors.white),
                            const SizedBox(width: 8),
                            _buildOrderButton(
                                'Prêt', AppColors.amber, AppColors.forest),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Bottom Navigation
        Positioned(
          bottom: 40,
          left: 24,
          right: 24,
          child: Row(
            children: [
              _buildNavButton(
                  '📦 Catalogue', () => onNavigate(BusinessScreen.catalog)),
              const SizedBox(width: 12),
              _buildNavButton(
                  '📈 Stats', () => onNavigate(BusinessScreen.stats)),
              const SizedBox(width: 12),
              _buildNavButton(
                  '⚙️ Profil', () => onNavigate(BusinessScreen.profile)),
            ],
          ),
        ),
      ],
    );
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

  Widget _buildOrderButton(String text, Color bg, Color textCol) {
    return Expanded(
      child: InkWell(
        onTap: () {},
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

            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: ['Tout', 'Plats', 'Entrées', 'Boissons']
                    .asMap()
                    .entries
                    .map((e) {
                  final isFirst = e.key == 0;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFirst ? AppColors.forest : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          isFirst ? null : Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color:
                            isFirst ? Colors.white : AppColors.mutedForeground,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Grid
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
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
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final item = provider.products[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: item.imageUrl != null
                                  ? Image.network(item.imageUrl!,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.warmWhite,
                                      child: const Icon(LucideIcons.image,
                                          color: AppColors.mutedForeground)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.forest)),
                                  Text('${item.price} MAD',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.gold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () => onNavigate(
                                            BusinessScreen.editProduct,
                                            index: index),
                                        child: const Icon(LucideIcons.pencil,
                                            color: AppColors.gold, size: 16),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            provider.deleteProduct(index),
                                        child: const Icon(LucideIcons.trash2,
                                            color: AppColors.destructive,
                                            size: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  List<BusinessProduct> _previewItems = [];
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
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(item.category,
                              style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${item.price} MAD',
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
          onPressed: () {
            context.read<ProductProvider>().addBatch(_previewItems);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${_previewItems.length} produits importés avec succès !'),
                  backgroundColor: AppColors.online),
            );
            widget.onNavigate(BusinessScreen.catalog);
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.sage.withOpacity(0.2)),
                  ),
                  child: const Column(
                    children: [
                      Icon(LucideIcons.camera,
                          color: AppColors.forest, size: 32),
                      SizedBox(height: 8),
                      Text('Ajouter une photo',
                          style: TextStyle(
                              color: AppColors.mutedForeground, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildField('Nom du produit', 'Ex: Tajine Berbère',
                    controller: _nameController),
                const SizedBox(height: 16),
                _buildField('Description', 'Détails du produit...',
                    lines: 2, controller: _descController),
                const SizedBox(height: 16),
                _buildField('Prix (MAD)', '0.00',
                    keyboardType: TextInputType.number,
                    controller: _priceController),
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
                ElevatedButton(
                  onPressed: () {
                    final p = BusinessProduct(
                      name: _nameController.text,
                      description: _descController.text,
                      price: double.tryParse(_priceController.text) ?? 0.0,
                      category: _category,
                      isAvailable: _isDispo,
                      imageUrl:
                          'https://images.unsplash.com/photo-1541529086526-db283c563270?w=400&h=300&fit=crop',
                    );
                    context.read<ProductProvider>().addProduct(p);
                    widget.onNavigate(BusinessScreen.catalog);
                  },
                  child: const Text('Enregistrer le produit'),
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

  @override
  void initState() {
    super.initState();
    final p = context.read<ProductProvider>().products[widget.index];
    _nameController = TextEditingController(text: p.name);
    _descController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.price.toString());
    _isDispo = p.isAvailable;
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
                _buildField('Nom du produit', 'Ex: Tajine Berbère',
                    controller: _nameController),
                const SizedBox(height: 16),
                _buildField('Description', 'Détails du produit...',
                    lines: 2, controller: _descController),
                const SizedBox(height: 16),
                _buildField('Prix (MAD)', '0.00',
                    keyboardType: TextInputType.number,
                    controller: _priceController),
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
                ElevatedButton(
                  onPressed: () {
                    final old =
                        context.read<ProductProvider>().products[widget.index];
                    final p = BusinessProduct(
                      name: _nameController.text,
                      description: _descController.text,
                      price: double.tryParse(_priceController.text) ?? 0.0,
                      category: old.category,
                      isAvailable: _isDispo,
                      imageUrl: old.imageUrl,
                    );
                    context
                        .read<ProductProvider>()
                        .updateProduct(widget.index, p);
                    widget.onNavigate(BusinessScreen.catalog);
                  },
                  child: const Text('Mettre à jour'),
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
}

// ============ ORDER DETAIL VIEW ============
class _OrderDetailView extends StatelessWidget {
  final Function(BusinessScreen) onNavigate;

  const _OrderDetailView({required this.onNavigate});

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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commande #1042',
                        style: TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text('Il y a 5 min',
                        style: TextStyle(
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
                  child: const Text('En cours',
                      style: TextStyle(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.cardShadow),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alae Benchakroun',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.forest)),
                            Text('23, Rue Al Andalous',
                                style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.sage.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(LucideIcons.phone,
                            color: AppColors.sage, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildOrderItem(2, 'Couscous Royal', '170'),
                _buildOrderItem(1, 'Thé à la Menthe', '15'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.cardShadow),
                  child: Column(
                    children: [
                      _buildStep('Commande reçue', true, true),
                      _buildStep('En préparation', true, true),
                      _buildStep('Prêt pour livraison', false, true,
                          isCurrent: true),
                      _buildStep('Livrée', false, false),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.printer, size: 16),
                  label: const Text('Imprimer'),
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

  Widget _buildStep(String label, bool isDone, bool showLine,
      {bool isCurrent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.sage
                      : (isCurrent ? AppColors.amber : AppColors.warmWhite),
                  shape: BoxShape.circle),
              child: isDone
                  ? const Icon(LucideIcons.check, color: Colors.white, size: 12)
                  : null,
            ),
            if (showLine)
              Container(
                  width: 2,
                  height: 24,
                  color: isDone ? AppColors.sage : Colors.black12),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(label,
              style: TextStyle(
                  color: isDone ? AppColors.sage : AppColors.mutedForeground,
                  fontWeight:
                      isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13)),
        ),
      ],
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
