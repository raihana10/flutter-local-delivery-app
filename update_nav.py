import sys

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace the list of nav items
    old_items = """          _buildNavItem(Icons.home, 'Accueil', 0),
          _buildNavItem(Icons.search, 'Rechercher', 1),
          _buildNavItem(Icons.shopping_cart, 'Panier', 2),
          _buildNavItem(Icons.person, 'Profil', 3),"""
    new_items = """          _buildNavItem(Icons.home, 'Accueil', 0),
          _buildNavItem(Icons.shopping_cart, 'Panier', 1),
          _buildNavItem(Icons.person, 'Profil', 2),"""
    content = content.replace(old_items, new_items)

    # In _buildNavItem switch statement
    old_switch = """        switch (index) {
          case 2:
            targetScreen = const CartScreen();
            break;
          case 3:
            targetScreen = const ClientProfileScreen();
            break;
        }"""
    new_switch = """        switch (index) {
          case 1:
            targetScreen = const CartScreen();
            break;
          case 2:
            targetScreen = const ClientProfileScreen();
            break;
        }"""
    content = content.replace(old_switch, new_switch)

    # Replace badge index
    old_badge1 = "if (index == 2) // Cart icon with badge"
    new_badge1 = "if (index == 1) // Cart icon with badge"
    content = content.replace(old_badge1, new_badge1)

    with open(filepath, 'w') as f:
        f.write(content)

files = [
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/market_list_screen.dart',
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/pharmacy_list_screen.dart',
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/restaurant_list_screen.dart'
]

for file in files:
    process_file(file)
