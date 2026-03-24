import os

old_popup = """                                              PopupMenuButton<String>(
                                                offset: const Offset(0, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                onSelected: (value) async {
                                                  if (value == 'logout') {
                                                    await context
                                                        .read<AuthProvider>()
                                                        .logout();
                                                    if (mounted) {
                                                      Navigator.of(context)
                                                          .pushReplacementNamed(
                                                              '/');
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'logout',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.logout,
                                                            color: Colors.red,
                                                            size: 20),
                                                        SizedBox(width: 8),
                                                        Text('Déconnexion'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                        color: AppColors.primary
                                                            .withOpacity(0.3)),
                                                  ),
                                                  child: const Icon(
                                                      Icons.person,
                                                      color: AppColors.primary),
                                                ),
                                              ),"""

new_icon = """                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                                                  );
                                                },
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                        color: AppColors.primary
                                                            .withOpacity(0.3)),
                                                  ),
                                                  child: const Icon(
                                                      Icons.location_on,
                                                      color: AppColors.primary),
                                                ),
                                              ),"""


files = [
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/market_list_screen.dart',
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/pharmacy_list_screen.dart',
    '/Users/mac/Documents/livraison_app/frontend/lib/presentation/screens/client/restaurant_list_screen.dart'
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()

    # Add order_tracking_screen setup in case not imported
    if "import 'order_tracking_screen.dart';" not in content:
        content = content.replace("import 'order_history_screen.dart';", "import 'order_history_screen.dart';\nimport 'order_tracking_screen.dart';")

    if old_popup in content:
        content = content.replace(old_popup, new_icon)
    
    with open(file, 'w') as f:
        f.write(content)
