import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final String? type;
  final double size;
  final double iconSize;
  final BorderRadius? borderRadius;

  const ProductImagePlaceholder({
    super.key,
    this.type,
    this.size = 80,
    this.width,
    this.height,
    this.iconSize = 32,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    List<Color> gradient;

    switch (type) {
      case 'pharmacy':
      case 'pharmacie':
        icon = LucideIcons.pill;
        color = Colors.teal;
        break;
      case 'grocery':
      case 'super-marche':
      case 'supermarche':
        icon = LucideIcons.shoppingBasket;
        color = Colors.orange;
        break;
      case 'meal':
      case 'restaurant':
        icon = LucideIcons.utensils;
        color = Colors.redAccent;
        break;
      default:
        icon = LucideIcons.package;
        color = Colors.grey;
        break;
    }
    gradient = [Colors.orange.shade100, Colors.orange.shade200];

    return Container(
      width: width ?? size,
      height: height ?? size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.15),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
