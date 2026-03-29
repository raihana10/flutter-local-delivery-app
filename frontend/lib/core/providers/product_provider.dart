import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../../data/models/business_model.dart';
import 'package:app/core/services/image_upload_service.dart';

class ProductProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _imageService = ImageUploadService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Business> _businesses = [];
  List<Produit> _products = [];
  List<Produit> _businessProducts = []; // Products for a specific business
  List<Promotion> _promotions = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Business> get businesses => _businesses;
  List<Produit> get products => _products;
  List<Produit> get businessProducts => _businessProducts;
  List<Promotion> get promotions => _promotions;

  // Promotions management
  Future<void> fetchPromotions() async {
    try {
      final response = await _supabase
          .from('promotion')
          .select('*, produit(*, business(*, app_user(*)))');
          
      final list = (response as List).whereType<Map<String, dynamic>>();
      _promotions = [];
      for (var item in list) {
        try {
          _promotions.add(Promotion.fromJson(item));
        } catch (e) {
          debugPrint('FAILED TO PARSE PROMO ITEM: $item - Error: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching promotions: $e');
    }
  }

  Future<void> fetchPromotionsByBusiness(int businessId) async {
    try {
      final response = await _supabase
          .from('promotion')
          .select('*, produit!inner(*)')
          .eq('produit.id_business', businessId);
      _promotions =
          (response as List).map((json) => Promotion.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching business promotions: $e');
    }
  }

  Future<bool> addPromotion(Promotion promotion, int businessId) async {
    try {
      await _supabase.from('promotion').insert(promotion.toJson());
      await fetchPromotionsByBusiness(businessId);
      return true;
    } catch (e) {
      debugPrint('Error adding promotion: $e');
      return false;
    }
  }

  Future<bool> deletePromotion(int id, int businessId) async {
    try {
      await _supabase.from('promotion').delete().eq('id_promotion', id);
      await fetchPromotionsByBusiness(businessId);
      return true;
    } catch (e) {
      debugPrint('Error deleting promotion: $e');
      return false;
    }
  }

  // Fetch business details by ID
  Future<Map<String, dynamic>?> fetchBusinessById(int businessId) async {
    try {
      final response = await _supabase
          .from('business')
          .select('*, app_user(*)')
          .eq('id_business', businessId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching business by ID: $e');
      return null;
    }
  }

  Future<void> fetchBusinesses(String type) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('business')
          .select('*, app_user(*)')
          .eq('type_business', type)
          .eq('est_actif', true);

      _businesses = (response as List).map((json) => Business.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching businesses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductsByBusiness(int businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('produit')
          .select('*')
          .eq('id_business', businessId);

      _businessProducts = (response as List).map((json) => Produit.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query, {String? type}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var request = _supabase.from('produit').select('*, business(*)');
      
      if (type != null) {
        request = request.eq('type_produit', type);
      }
      
      if (query.isNotEmpty) {
        request = request.ilike('nom_produit', '%$query%');
      }

      final response = await request;
      _products = (response as List).map((json) => Produit.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Business Specific Methods ---

  Future<String?> uploadImage(XFile file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = await _imageService.uploadProductImage(file);
      if (url == null) {
        throw Exception("L'upload de l'image a échoué. Vérifiez que le bucket 'alae' existe et est public dans Supabase.");
      }
      return url;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Produit produit) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('produit').insert(produit.toJson());
      await fetchProductsByBusiness(produit.idBusiness);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(Produit produit) async {
    _isLoading = true;
    notifyListeners();

    try {
      final json = produit.toJson();
      final id = json.remove('id_produit'); // Remove PK from body for cleaner update

      print('DEBUG: Updating product ID: $id');
      print('DEBUG: Product Payload: $json');

      final response = await _supabase
          .from('produit')
          .update(json)
          .eq('id_produit', id)
          .select();
      
      if (response == null || (response as List).isEmpty) {
        throw Exception("Aucune ligne modifiée. Vérifiez que l'ID produit ($id) est correct.");
      }

      print('DEBUG: Update successful, response: ${response.first}');
      await fetchProductsByBusiness(produit.idBusiness);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleProductAvailability(Produit produit) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isCurrentlyAvailable = produit.deletedAt == null;
      final newDeletedAt = isCurrentlyAvailable ? DateTime.now().toIso8601String() : null;
      
      await _supabase
          .from('produit')
          .update({'deleted_at': newDeletedAt})
          .eq('id_produit', produit.id);
          
      await fetchProductsByBusiness(produit.idBusiness);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- File Import ---

  Future<List<Produit>> parseFile(File file, String extension) async {
    List<Produit> items = [];
    if (extension == 'csv') {
      try {
        final input = file.readAsStringSync();
        final rows = const CsvToListConverter().convert(input);
        for (var i = 1; i < rows.length; i++) {
          if (rows[i].length >= 2) {
            items.add(Produit(
              id: 0,
              idBusiness: 0,
              nom: rows[i][0]?.toString() ?? '',
              description: rows[i].length > 1 ? rows[i][1]?.toString() ?? '' : '',
              prix: double.tryParse(rows[i].length > 2 ? rows[i][2]?.toString() ?? '0' : '0') ?? 0.0,
              type: rows[i].length > 3 ? rows[i][3]?.toString() ?? 'meal' : 'meal',
              image: rows[i].length > 4 ? rows[i][4]?.toString() : 'https://images.unsplash.com/photo-1541529086526-db283c563270?w=400&h=300&fit=crop',
            ));
          }
        }
      } catch (e) {
        debugPrint('CSV parse error: $e');
      }
    } else if (extension == 'xlsx' || extension == 'xls') {
      final bytes = file.readAsBytesSync();
      final String filePath = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final excel = Excel.decodeBytes(bytes);
      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet != null) {
          for (var i = 1; i < sheet.rows.length; i++) {
            final row = sheet.rows[i];
            if (row.length >= 2) {
              items.add(Produit(
                id: 0,
                idBusiness: 0,
                nom: row[0]?.value?.toString() ?? '',
                description: row.length > 1 ? row[1]?.value?.toString() ?? '' : '',
                prix: double.tryParse(row.length > 2 ? row[2]?.value?.toString() ?? '0' : '0') ?? 0.0,
                type: row.length > 3 ? row[3]?.value?.toString() ?? 'meal' : 'meal',
              ));
            }
          }
        }
      }
    }
    return items;
  }

  Future<void> addBatch(List<Produit> items, int businessId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final toInsert = items.map((p) => {
        'id_business': businessId,
        'nom_produit': p.nom,
        'description': p.description,
        'prix_unitaire': p.prix,
        'type_produit': p.type,
        'image': p.image,
      }).toList();
      await _supabase.from('produit').insert(toInsert);
      await fetchProductsByBusiness(businessId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Batch insert error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
