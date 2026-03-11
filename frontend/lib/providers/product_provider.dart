import 'package:flutter/material.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/business_product.dart';

class ProductProvider with ChangeNotifier {
  List<BusinessProduct> _products = [
    BusinessProduct(name: 'Tajine de Poulet', price: 85, description: 'Tajine traditionnel', category: 'meal', imageUrl: 'https://images.unsplash.com/photo-1541529086526-db283c563270?w=400&h=300&fit=crop'),
    BusinessProduct(name: 'Couscous Royal', price: 120, description: 'Couscous royal complet', category: 'meal', imageUrl: 'https://images.unsplash.com/photo-1541529086526-db283c563270?w=400&h=300&fit=crop'),
    BusinessProduct(name: 'Harira', price: 35, description: 'Soupe traditionnelle', category: 'meal', imageUrl: 'https://images.unsplash.com/photo-1541529086526-db283c563270?w=400&h=300&fit=crop'),
    BusinessProduct(name: 'Thé à la Menthe', price: 15, description: 'Infusion fraîche', category: 'meal', imageUrl: 'https://images.unsplash.com/photo-1541529086526-db283c563270?w=400&h=300&fit=crop'),
  ];

  List<BusinessProduct> get products => _products;

  void addProduct(BusinessProduct product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(int index, BusinessProduct product) {
    if (index >= 0 && index < _products.length) {
      _products[index] = product;
      notifyListeners();
    }
  }

  void deleteProduct(int index) {
     if (index >= 0 && index < _products.length) {
      _products.removeAt(index);
      notifyListeners();
    }
  }

  Future<List<BusinessProduct>> parseFile(File file, String extension) async {
    List<BusinessProduct> items = [];
    if (extension == 'csv') {
      try {
        final input = file.readAsStringSync();
        // Try both ways to see what works
        final converter = CsvToListConverter();
        List<List<dynamic>> rows = converter.convert(input);
        
        for (var i = 1; i < rows.length; i++) {
          if (rows[i].length >= 4) {
            items.add(BusinessProduct.fromCsv(rows[i]));
          }
        }
      } catch (e) {
        debugPrint('CSV Parse Error: $e');
      }
    } else if (extension == 'xlsx' || extension == 'xls') {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet != null) {
          for (var i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            if (row.length >= 4) {
              items.add(BusinessProduct(
                name: row[0]?.value?.toString() ?? '',
                description: row[1]?.value?.toString() ?? '',
                price: double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0,
                category: BusinessProduct.mapCategory(row[3]?.value?.toString() ?? 'meal'),
                isAvailable: true,
              ));
            }
          }
        }
      }
    }
    return items;
  }

  void addBatch(List<BusinessProduct> items) {
    _products.addAll(items);
    notifyListeners();
  }
}
