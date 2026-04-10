import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'restaurant_detail_screen.dart';
import '../../../data/models/business_model.dart';
import '../../widgets/promotions_banner.dart';

class GenericVerticalListScreen extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final String category; // 'promos', 'restaurants', 'pharmacies', 'markets'

  const GenericVerticalListScreen({
    super.key,
    required this.title,
    required this.items,
    this.category = 'restaurants',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (category == 'promos') {
            return _buildPromoCard(items[index]);
          } else {
            return _buildBusinessCard(context, items[index], index);
          }
        },
      ),
    );
  }

  Widget _buildPromoCard(dynamic promo) {
    if (promo is Promotion) {
      return RealPromoCard(promo: promo);
    }

    final Map<String, dynamic> promoMap = promo as Map<String, dynamic>;
    final color = promoMap['color'] as Color? ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (promoMap.containsKey('emoji'))
                      Text(promoMap['emoji'] as String,
                          style: const TextStyle(fontSize: 24)),
                    if (promoMap.containsKey('icon'))
                      Icon(promoMap['icon'] as IconData, color: color, size: 24),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        promoMap['title'] as String,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  promoMap['subtitle'] as String,
                  style: const TextStyle(
                      color: AppColors.card,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBusinessCard(
      BuildContext context, Map<String, dynamic> info, int index) {
    final businessUser = info['app_user'] ?? {};
    final idBusiness = info['id_business'] ?? '0';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(
              restaurantName: businessUser['nom'] ?? 'Magasin',
              heroTag: 'generic_${idBusiness}_$index',
              businessId: idBusiness.toString(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Hero(
              tag: 'generic_${idBusiness}_$index',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.background,
                  image: info['pdp'] != null
                      ? DecorationImage(
                          image: NetworkImage(info['pdp']), fit: BoxFit.cover)
                      : null,
                ),
                child: info['pdp'] == null
                    ? const Center(
                        child: Icon(Icons.store,
                            size: 32, color: AppColors.primary))
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessUser['nom'] ?? 'Magasin',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info['description'] ?? 'Magasin partner',
                    style: TextStyle(
                        color: AppColors.mutedForeground, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
