import 'dart:io';
import 'package:flutter/material.dart';

class ImageUtils {
  static ImageProvider getImageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('assets/images/placeholder.png'); // Fallback to asset if you have one, or use a default logo elsewhere
    }
    
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    
    if (path.startsWith('file://')) {
      try {
        return FileImage(File(Uri.parse(path).toFilePath()));
      } catch (e) {
        debugPrint('Error parsing file URI: $e');
        return FileImage(File(path));
      }
    }
    
    return FileImage(File(path));
  }
}
