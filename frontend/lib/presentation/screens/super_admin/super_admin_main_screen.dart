import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/core/constants/app_colors.dart';

import 'dashboard_screen.dart';
import 'users_management_screen.dart';
import 'orders_management_screen.dart';
import 'payments_screen.dart';
import 'statistics_screen.dart';
import 'notifications_screen.dart';

class SuperAdminMainScreen extends StatefulWidget {
  const SuperAdminMainScreen({super.key});

  @override
  State<SuperAdminMainScreen> createState() => _SuperAdminMainScreenState();
}

class _SuperAdminMainScreenState extends State<SuperAdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const UsersManagementScreen(),
    const OrdersManagementScreen(),
    const PaymentsScreen(),
    const StatisticsScreen(),
    const NotificationsScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': LucideIcons.layoutDashboard, 'title': 'Dashboard'},
    {'icon': LucideIcons.users, 'title': 'Utilisateurs'},
    {'icon': LucideIcons.package2, 'title': 'Commandes'},
    {'icon': LucideIcons.wallet, 'title': 'Paiements'},
    {'icon': Icons.bar_chart, 'title': 'Statistiques'},
    {'icon': LucideIcons.bell, 'title': 'Notifications'},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: Text(_menuItems[_selectedIndex]['title']),
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.logOut),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    )
                  ],
                ),
          drawer: isDesktop ? null : _buildDrawer(),
          body: isDesktop
              ? Row(
                  children: [
                    _buildSidebar(),
                    Expanded(
                      child: _screens[_selectedIndex],
                    ),
                  ],
                )
              : _screens[_selectedIndex],
          bottomNavigationBar: isDesktop
              ? null
              : BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    _onItemTapped(index);
                  },
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.accent,
                  unselectedItemColor: AppColors.mutedForeground,
                  items: [
                    const BottomNavigationBarItem(
                        icon: Icon(LucideIcons.layoutDashboard),
                        label: 'Dashboard'),
                    const BottomNavigationBarItem(
                        icon: Icon(LucideIcons.users), label: 'Utilisateurs'),
                    const BottomNavigationBarItem(
                        icon: Icon(LucideIcons.package2), label: 'Commandes'),
                    const BottomNavigationBarItem(
                        icon: Icon(LucideIcons.wallet), label: 'Paiements'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.bar_chart), label: 'Statistiques'),
                    const BottomNavigationBarItem(
                        icon: Icon(LucideIcons.bell), label: 'Notifications'),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: AppColors.primary,
            width: double.infinity,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.shieldCheck,
                    size: 48, color: AppColors.accent),
                SizedBox(height: 10),
                Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    _menuItems[index]['icon'],
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.mutedForeground,
                  ),
                  title: Text(
                    _menuItems[index]['title'],
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.accent : AppColors.foreground,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withOpacity(0.05),
                  onTap: () {
                    _onItemTapped(index);
                    Navigator.pop(context); // Close drawer
                  },
                );
              },
            ),
          ),
          ListTile(
            leading:
                const Icon(LucideIcons.logOut, color: AppColors.destructive),
            title: const Text('Déconnexion',
                style: TextStyle(color: AppColors.destructive)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppColors.card,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            color: AppColors.primary,
            child: const Column(
              children: [
                Icon(LucideIcons.shieldCheck,
                    size: 48, color: AppColors.accent),
                SizedBox(height: 10),
                Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _onItemTapped(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.accent.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _menuItems[index]['icon'],
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.mutedForeground,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _menuItems[index]['title'],
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              icon:
                  const Icon(LucideIcons.logOut, color: AppColors.destructive),
              label: const Text('Déconnexion',
                  style: TextStyle(color: AppColors.destructive)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.destructive),
                foregroundColor: AppColors.destructive,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}
