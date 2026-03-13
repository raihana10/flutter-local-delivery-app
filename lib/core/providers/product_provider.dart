
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../../data/models/business_model.dart';

class ProductProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Business> _businesses = [];
  List<Produit> _products = [];
  List<Produit> _businessProducts = []; // Products for a specific business

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Business> get businesses => _businesses;
  List<Produit> get products => _products;
  List<Produit> get businessProducts => _businessProducts;

  // Search businesses by type
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

  // Fetch products for a specific business
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

  // Search products globally or by category
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

  Future<bool> addProduct(Produit produit) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('produit').insert(produit.toJson());
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

  Future<bool> updateProduct(Produit produit) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('produit')
          .update(produit.toJson())
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

  Future<bool> deleteProduct(int productId, int businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('produit').delete().eq('id_produit', productId);
      await fetchProductsByBusiness(businessId);
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
            ));
          }
        }
      } catch (e) {
        debugPrint('CSV parse error: $e');
      }
    } else if (extension == 'xlsx' || extension == 'xls') {
      final bytes = file.readAsBytesSync();
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
