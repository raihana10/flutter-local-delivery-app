import sys
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Add order_history_screen import if not present
    if "import 'order_history_screen.dart';" not in content:
        content = content.replace("import 'cart_screen.dart';", "import 'cart_screen.dart';\nimport 'order_history_screen.dart';")

    # Replace the list of nav items
    old_items = """          _buildNavItem(Icons.home, 'Accueil', 0),
          _buildNavItem(Icons.shopping_cart, 'Panier', 1),
          _buildNavItem(Icons.person, 'Profil', 2),"""
    new_items = """          _buildNavItem(Icons.home, 'Accueil', 0),
          _buildNavItem(Icons.shopping_cart, 'Panier', 1),
          _buildNavItem(Icons.history, 'Historique', 2),
          _buildNavItem(Icons.person, 'Profil', 3),"""
    content = content.replace(old_items, new_items)

    # In _buildNavItem switch statement
    old_switch = """        switch (index) {
          case 1:
            targetScreen = const CartScreen();
            break;
          case 2:
            targetScreen = const ClientProfileScreen();
            break;
        }"""
    new_switch = """        switch (index) {
          case 1:
            targetScreen = const CartScreen();
            break;
          case 2:
            targetScreen = const OrderHistoryScreen();
            break;
          case 3:
            targetScreen = const ClientProfileScreen();
            break;
        }"""
    content = content.replace(old_switch, new_switch)

    with open(filepath, 'w') as f:
        f.write(content)

files = [
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/client_home_screen.dart',
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/market_list_screen.dart',
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/pharmacy_list_screen.dart',
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/restaurant_list_screen.dart'
]

for file in files:
    process_file(file)
