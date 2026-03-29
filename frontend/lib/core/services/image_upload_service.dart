import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Choisir une image depuis la galerie ou l'appareil photo
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100, // On gère la compression nous-mêmes ensuite
      );
      if (pickedFile != null) return File(pickedFile.path);
    } catch (e) {
      print('DEBUG: pickImage error: $e');
    }
    return null;
  }

  /// Compresser l'image avant l'upload (seuil de 800Ko)
  Future<File?> compressImage(File file) async {
    try {
      final directory = await getTemporaryDirectory();
      final String targetPath = p.join(directory.path, "temp_${DateTime.now().millisecondsSinceEpoch}.jpg");

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // Réduit nettement le poids sans trop sacrifier la netteté
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
    } catch (e) {
      print('DEBUG: compression error: $e');
    }
    return file; // Retourne l'original si la compression échoue
  }

  /// Uploader l'image vers Supabase Storage
  /// Bucket: 'product-image'
  Future<String?> uploadProductImage(File file) async {
    try {
      // 1. Compresser l'image
      final File? compressedFile = await compressImage(file);
      if (compressedFile == null) return null;

      // 2. Préparer le chemin unique (ext pour rester propre)
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'products/$fileName';

      // 3. Upload vers le bucket
      // IMPORTANT: Le bucket 'product-image' doit être existant et public
      await _supabase.storage.from('product-image').upload(
        filePath,
        compressedFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 4. Récupérer l'URL publique
      final String publicUrl = _supabase.storage.from('product-image').getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      print('DEBUG: upload error: $e');
      return null;
    }
  }

  /// Supprimer une image du storage lors de la suppression d'un produit
  Future<void> deleteImage(String publicUrl) async {
    try {
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      // Analyse l'URL pour extraire le chemin relatif après le nom du bucket
      // Format URL: /storage/v1/object/public/product-image/products/file.jpg
      final productIndex = pathSegments.indexOf('products');
      if (productIndex != -1) {
        final String relativePath = pathSegments.sublist(productIndex).join('/');
        await _supabase.storage.from('product-image').remove([relativePath]);
      }
    } catch (e) {
      print('DEBUG: delete image error: $e');
    }
  }
}
