import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Choisir une image (supporte Web et Mobile)
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      return pickedFile;
    } catch (e) {
      print('DEBUG: pickImage error: $e');
      return null;
    }
  }

  /// Uploader l'image vers Supabase Storage
  /// Bucket: 'alae' (As requested for consistency with business photos)
  Future<String?> uploadProductImage(XFile xFile) async {
    try {
      final bytes = await xFile.readAsBytes();
      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'products/$fileName'; // Restored folder structure

      // 1. Get MIME type from extension
      final ext = xFile.name.split('.').last.toLowerCase();
      final mimeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp'
      };
      final contentType = mimeMap[ext] ?? 'image/jpeg';

      // 2. Upload using binary to support Web
      await _supabase.storage.from('alae').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: contentType,
            ),
          );

      // 3. Get Public URL
      final String publicUrl = _supabase.storage.from('alae').getPublicUrl(filePath);
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
      // Format URL: /storage/v1/object/public/alae/products/prod_123.jpg
      final productIndex = pathSegments.indexOf('products');
      if (productIndex != -1) {
        final String relativePath = pathSegments.sublist(productIndex).join('/');
        await _supabase.storage.from('alae').remove([relativePath]);
      }
    } catch (e) {
      print('DEBUG: delete image error: $e');
    }
  }
}
