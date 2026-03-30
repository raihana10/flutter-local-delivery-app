import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/super_admin_api_service.dart';

class BusinessDetailAdminScreen extends StatefulWidget {
  final int idBusiness;
  const BusinessDetailAdminScreen({super.key, required this.idBusiness});

  @override
  State<BusinessDetailAdminScreen> createState() =>
      _BusinessDetailAdminScreenState();
}

class _BusinessDetailAdminScreenState extends State<BusinessDetailAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _business;
  final _apiService = SuperAdminApiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final res = await _apiService.getBusinessDetail(widget.idBusiness);
    if (mounted) {
      setState(() {
        _business = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nom = _business?['nom_business'] ?? 'Business Inconnu';
    final type = _business?['type_business'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(nom),
            const SizedBox(width: 8),
            _buildBadge(type),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '📦 Commandes'),
            Tab(text: '🛍️ Catalogue'),
            Tab(text: '🏷️ Promotions'),
            Tab(text: '🕐 Horaires'),
            Tab(text: '📊 Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BusinessCommandesTab(idBusiness: widget.idBusiness),
          _BusinessCatalogueTab(idBusiness: widget.idBusiness),
          _BusinessPromotionsTab(idBusiness: widget.idBusiness),
          _BusinessHoursTab(
              idBusiness: widget.idBusiness, businessData: _business),
          _BusinessStatsTab(idBusiness: widget.idBusiness),
        ],
      ),
    );
  }

  Widget _buildBadge(String type) {
    String label = type;
    if (type == 'restaurant') label = 'restaurant 🍽️';
    if (type == 'super-marche') label = 'supermarché 🛒';
    if (type == 'pharmacie') label = 'pharmacie 💊';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.primary)),
    );
  }
}

// ---------------------------------------------------------
// Tab 1 : Commandes
// ---------------------------------------------------------
class _BusinessCommandesTab extends StatefulWidget {
  final int idBusiness;
  const _BusinessCommandesTab({required this.idBusiness});

  @override
  State<_BusinessCommandesTab> createState() => _BusinessCommandesTabState();
}

class _BusinessCommandesTabState extends State<_BusinessCommandesTab> {
  final _api = SuperAdminApiService();
  List<dynamic> _allCommandes = [];
  List<dynamic> _filtered = [];
  String _selectedStatut = 'Toutes';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.getBusinessCommandes(widget.idBusiness);
    if (mounted) {
      setState(() {
        _allCommandes = res;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedStatut == 'Toutes') {
        _filtered = List.from(_allCommandes);
      } else {
        _filtered = _allCommandes
            .where((c) => c['statut_commande'] == _selectedStatut.toLowerCase())
            .toList();
      }
    });
  }

  Future<void> _changeStatut(int id, String current) async {
    final options = ['confirmee', 'preparee', 'en_livraison', 'livree'];
    final currentIndex = options.indexOf(current);
    if (currentIndex == -1 || currentIndex == options.length - 1) return;

    final nextStatut = options[currentIndex + 1];
    await _api.updateCommandeStatut(widget.idBusiness, id, nextStatut);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8,
            children: [
              'Toutes',
              'Confirmée',
              'Préparée',
              'En livraison',
              'Livrée'
            ].map((s) {
              final isSelected = _selectedStatut == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedStatut = s);
                    _applyFilter();
                  }
                },
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final c = _filtered[i];
                final prixTotal = c['prix_total'] ?? 0;
                final frais = c['frais_livraison'] ?? 0;
                final client =
                    c['client']?['id_user']?['nom'] ?? 'Client Inconnu';
                final statut = c['statut_commande'] ?? 'inconnu';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Commande #${c['id_commande']} - $client'),
                    subtitle: Text('Montant: ${prixTotal + frais} MAD'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(label: Text(statut)),
                        const SizedBox(width: 8),
                        if (statut != 'livree' && statut != 'annulee')
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () =>
                                _changeStatut(c['id_commande'], statut),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------
// Tab 2 : Catalogue
// ---------------------------------------------------------
class _BusinessCatalogueTab extends StatefulWidget {
  final int idBusiness;
  const _BusinessCatalogueTab({required this.idBusiness});

  @override
  State<_BusinessCatalogueTab> createState() => _BusinessCatalogueTabState();
}

class _BusinessCatalogueTabState extends State<_BusinessCatalogueTab> {
  final _api = SuperAdminApiService();
  List<dynamic> _produits = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.getBusinessProduits(widget.idBusiness);
    if (mounted) setState(() => _produits = res);
  }

  void _showProduitDialog([dynamic produit]) {
    final nomCtrl = TextEditingController(text: produit?['nom_produit'] ?? '');
    final descCtrl = TextEditingController(text: produit?['description'] ?? '');
    final prixCtrl = TextEditingController(
        text: (produit?['prix_unitaire'] ?? '').toString());
    String typeSelection = produit?['type_produit'] ?? 'meal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: Text(produit == null ? 'Ajouter Produit' : 'Modifier Produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nomCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nom produit')),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3),
                TextField(
                    controller: prixCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Prix unitaire (MAD)'),
                    keyboardType: TextInputType.number),
                DropdownButton<String>(
                  value: typeSelection,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'meal', child: Text('Meal')),
                    DropdownMenuItem(value: 'grocery', child: Text('Grocery')),
                    DropdownMenuItem(
                        value: 'pharmacy', child: Text('Pharmacy')),
                  ],
                  onChanged: (val) {
                    setDialogState(() => typeSelection = val!);
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'nom_produit': nomCtrl.text,
                  'description': descCtrl.text,
                  'prix_unitaire': double.tryParse(prixCtrl.text) ?? 0.0,
                  'type_produit': typeSelection,
                };
                if (produit == null) {
                  await _api.addProduit(widget.idBusiness, data);
                } else {
                  await _api.updateProduit(
                      widget.idBusiness, produit['id_produit'], data);
                }
                if (mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Sauvegarder'),
            )
          ],
        );
      }),
    );
  }

  void _showCsvDialog() {
    // In a real flutter web/desktop app, you would use file_picker to get text content.
    // For this mockup, we'll simulate reading a hardcoded string as a proof of concept.
    final exampleCsv =
        "Nom Test,Desc Test,100.0,meal\nProduit 2,Desc 2,50.0,grocery";
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Importer CSV'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Format CSV: nom_produit,description,prix_unitaire,type_produit'),
                  const SizedBox(height: 8),
                  Container(
                      color: Colors.grey[200],
                      padding: const EdgeInsets.all(8),
                      child: const Text('Pizza,Tomate,45.00,meal')),
                  const SizedBox(height: 16),
                  const Text(
                      'Simulation import fichier (cliquer pour imiter fichier choisi)'),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () async {
                    final res = await _api.importProduitsCsv(
                        widget.idBusiness, 'nom,desc,prix,type\n$exampleCsv');
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Résultat: ${res['inserted'] ?? 0} insérés')));
                      _load();
                    }
                  },
                  child: const Text('Importer'),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter produit'),
                  onPressed: () => _showProduitDialog()),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importer CSV'),
                  onPressed: _showCsvDialog)
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _produits.length,
            itemBuilder: (ctx, i) {
              final p = _produits[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(p['nom_produit']),
                  subtitle: Text(
                      '${p['prix_unitaire']} MAD - Type: ${p['type_produit']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: p['est_dispo'] ?? true,
                        onChanged: (val) {
                          _api.updateProduit(widget.idBusiness, p['id_produit'],
                              {'est_dispo': val}).then((_) => _load());
                        },
                      ),
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showProduitDialog(p)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _api
                                .deleteProduit(
                                    widget.idBusiness, p['id_produit'])
                                .then((_) => _load());
                          }),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------
// Tab 3 : Promotions
// ---------------------------------------------------------
class _BusinessPromotionsTab extends StatefulWidget {
  final int idBusiness;
  const _BusinessPromotionsTab({required this.idBusiness});
  @override
  State<_BusinessPromotionsTab> createState() => _BusinessPromotionsTabState();
}

class _BusinessPromotionsTabState extends State<_BusinessPromotionsTab> {
  final _api = SuperAdminApiService();
  List<dynamic> _promos = [];
  List<dynamic> _produits = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pRes = await _api.getBusinessPromotions(widget.idBusiness);
    final prRes = await _api.getBusinessProduits(widget.idBusiness);
    if (mounted)
      setState(() {
        _promos = pRes;
        _produits = prRes;
      });
  }

  void _showPromoDialog() {
    double pct = 10;
    String code = '';
    int? selProduit =
        _produits.isNotEmpty ? _produits.first['id_produit'] : null;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
                  title: const Text('Ajouter promotion'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_produits.isNotEmpty)
                        DropdownButton<int>(
                          value: selProduit,
                          isExpanded: true,
                          items: _produits
                              .map((p) => DropdownMenuItem<int>(
                                  value: p['id_produit'],
                                  child: Text(p['nom_produit'])))
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => selProduit = val),
                        ),
                      const SizedBox(height: 16),
                      Text('Pourcentage: ${pct.toInt()}%'),
                      Slider(
                        value: pct,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        onChanged: (val) => setDialogState(() => pct = val),
                      ),
                      TextField(
                        decoration: const InputDecoration(
                            labelText: 'Code Promo (optionnel)'),
                        onChanged: (val) => code = val,
                      )
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler')),
                    ElevatedButton(
                        onPressed: () async {
                          if (selProduit == null) return;
                          await _api.createPromotion(widget.idBusiness, {
                            'id_produit': selProduit,
                            'pourcentage': pct,
                            'code_pro': code.isEmpty ? null : code,
                            'date_debut': DateTime.now().toIso8601String(),
                            'date_fin': DateTime.now()
                                .add(const Duration(days: 30))
                                .toIso8601String()
                          });
                          if (mounted) Navigator.pop(ctx);
                          _load();
                        },
                        child: const Text('Créer'))
                  ],
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter promotion'),
                  onPressed: _produits.isEmpty ? null : _showPromoDialog)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _promos.length,
            itemBuilder: (ctx, i) {
              final p = _promos[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                      '${p['code_pro'] ?? 'Sans code'} - ${p['pourcentage']}%'),
                  subtitle: Text('Produit: ${p['nom_produit']}'),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _api
                            .deletePromotion(
                                widget.idBusiness, p['id_promotion'])
                            .then((_) => _load());
                      }),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

// ---------------------------------------------------------
// Tab 4 : Horaires
// ---------------------------------------------------------
class _BusinessHoursTab extends StatefulWidget {
  final int idBusiness;
  final Map<String, dynamic>? businessData;
  const _BusinessHoursTab(
      {required this.idBusiness, required this.businessData});
  @override
  State<_BusinessHoursTab> createState() => _BusinessHoursTabState();
}

class _BusinessHoursTabState extends State<_BusinessHoursTab> {
  final _api = SuperAdminApiService();
  late Map<String, dynamic> _hours;

  @override
  void initState() {
    super.initState();
    final defaultHours = {
      'lun': '08:00-22:00',
      'mar': '08:00-22:00',
      'mer': '08:00-22:00',
      'jeu': '08:00-22:00',
      'ven': '08:00-22:00',
      'sam': '08:00-22:00',
      'dim': '08:00-22:00'
    };
    if (widget.businessData?['opening_hours'] != null) {
      _hours = Map<String, dynamic>.from(widget.businessData!['opening_hours']);
    } else {
      _hours = defaultHours;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ...['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'].map((jour) {
              final val = _hours[jour] ?? '08:00-22:00';
              final parts = val.toString().split('-');
              final isClosed = val == 'ferme';
              return Card(
                child: ListTile(
                  title: Text(jour.toUpperCase()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Fermé '),
                      Switch(
                          value: !isClosed,
                          onChanged: (v) {
                            setState(() {
                              _hours[jour] = v ? '08:00-22:00' : 'ferme';
                            });
                          }),
                      if (!isClosed) ...[
                        TextButton(
                            onPressed: () {},
                            child: Text(parts.isNotEmpty ? parts[0] : '08:00')),
                        const Text(' - '),
                        TextButton(
                            onPressed: () {},
                            child: Text(parts.length > 1 ? parts[1] : '22:00')),
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder'),
              onPressed: () async {
                await _api.updateBusinessHours(widget.idBusiness, _hours);
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Horaires sauvegardés')));
              },
            )
          ],
        ));
  }
}

// ---------------------------------------------------------
// Tab 5 : Stats
// ---------------------------------------------------------
class _BusinessStatsTab extends StatefulWidget {
  final int idBusiness;
  const _BusinessStatsTab({required this.idBusiness});
  @override
  State<_BusinessStatsTab> createState() => _BusinessStatsTabState();
}

class _BusinessStatsTabState extends State<_BusinessStatsTab> {
  final _api = SuperAdminApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _api.getBusinessStats(widget.idBusiness);
    if (mounted)
      setState(() {
        _stats = s;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final s = _stats ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildKpiCard(
                  '💰 Revenus totaux', '${s['revenus_totaux'] ?? 0} MAD'),
              _buildKpiCard('📦 Nb commandes', '${s['nb_commandes'] ?? 0}'),
              _buildKpiCard('⭐ Note moyenne', '${s['note_moyenne'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 24),
          const Card(
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Center(
                  child: Text('Graphique LineChart Revenus 7 derniers jours')),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
