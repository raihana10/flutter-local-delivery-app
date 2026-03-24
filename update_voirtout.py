import re

files_info = {
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/market_list_screen.dart': {
        'promos': """[
      { 'title': 'Fruits -30%', 'subtitle': 'Panier Fraîcheur', 'color': Colors.green, 'icon': Icons.shopping_basket },
      { 'title': 'Bio -15%', 'subtitle': 'Marché Bio', 'color': Colors.lightGreen, 'icon': Icons.eco },
      { 'title': 'Epicerie 2+1', 'subtitle': 'Super Market', 'color': AppColors.primary, 'icon': Icons.storefront },
    ]""",
        'promo_title': "'Promos du jour'",
        'all_title': "'Magasins proches'"
    },
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/pharmacy_list_screen.dart': {
        'promos': """[
      { 'title': 'Vitamines -30%', 'subtitle': 'Cure de vitalité', 'color': Colors.orange, 'icon': Icons.wb_sunny },
      { 'title': 'Cosmétiques -15%', 'subtitle': 'Soins du visage', 'color': Colors.pink, 'icon': Icons.face },
      { 'title': 'Bébés 2+1', 'subtitle': 'Couches & Laits', 'color': AppColors.primary, 'icon': Icons.child_care },
    ]""",
        'promo_title': "'Offres santé'",
        'all_title': "'Pharmacies proches'"
    },
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/restaurant_list_screen.dart': {
        'promos': """[
      { 'title': 'Pizza 50%', 'subtitle': 'Pizza Palace', 'color': AppColors.destructive, 'emoji': '🍕' },
      { 'title': 'Burger -20%', 'subtitle': 'Burger House', 'color': AppColors.accent, 'emoji': '🍔' },
      { 'title': 'Sushi -30%', 'subtitle': 'Sushi Bar', 'color': AppColors.primary, 'emoji': '🍱' },
    ]""",
        'promo_title': "'Promos du jour'",
        'all_title': "'Restaurants proches'"
    }
}

for file, info in files_info.items():
    with open(file, 'r') as f:
        content = f.read()

    # Import GenericVerticalListScreen
    if "import 'generic_vertical_list_screen.dart';" not in content:
        content = content.replace("import 'restaurant_detail_screen.dart';", "import 'restaurant_detail_screen.dart';\nimport 'generic_vertical_list_screen.dart';")

    # Replace Promos Voir tout
    # Need to match exactly: _buildSectionTitle( 'Promos du jour', 'Voir tout', () {}),
    # Since whitespace may vary, we use regex
    pattern1 = r"_buildSectionTitle\(\s*" + info['promo_title'] + r",\s*'Voir tout',\s*\(\)\s*\{*\}*\)"
    replacement1 = f"""_buildSectionTitle({info['promo_title']}, 'Voir tout', () {{
      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericVerticalListScreen(
        title: {info['promo_title']},
        category: 'promos',
        items: {info['promos']}
      )));
    }})"""
    content = re.sub(pattern1, replacement1, content)
    
    # Replace Magasins proches Voir tout
    # The variable for restaurants is _filteredRestaurants
    pattern2 = r"_buildSectionTitle\(\s*" + info['all_title'] + r",\s*'Voir tout',\s*\(\)\s*\{*\}*\)"
    replacement2 = f"""_buildSectionTitle({info['all_title']}, 'Voir tout', () {{
      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericVerticalListScreen(
        title: {info['all_title']},
        category: 'restaurants',
        items: _filteredRestaurants
      )));
    }})"""
    content = re.sub(pattern2, replacement2, content)

    with open(file, 'w') as f:
        f.write(content)

