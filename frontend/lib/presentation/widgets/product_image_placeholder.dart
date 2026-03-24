import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductImagePlaceholder extends StatelessWidget {
  final String? type;
  final double size;
  final double iconSize;
  final BorderRadius? borderRadius;

  const ProductImagePlaceholder({
    super.key,
    this.type,
    this.size = 80,
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
        icon = LucideIcons.pill;
        color = Colors.blue;
        gradient = [Colors.blue.shade100, Colors.blue.shade200];
        break;
      case 'grocery':
        icon = LucideIcons.shoppingBasket;
        color = Colors.green;
        gradient = [Colors.green.shade100, Colors.green.shade200];
        break;
      case 'meal':
      default:
        icon = LucideIcons.soup;
        color = Colors.orange;
        gradient = [Colors.orange.shade100, Colors.orange.shade200];
        break;
    }

    return Container(
      width: size,
      height: size,
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
