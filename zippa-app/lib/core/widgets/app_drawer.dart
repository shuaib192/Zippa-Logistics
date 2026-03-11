// ============================================
// 📱 SHARED APP DRAWER (app_drawer.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/core/providers/navigation_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zippa_app/core/constants/app_constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context);
    final user = authProvider.user;
    final isRider = user?.role == 'rider';
    final isVendor = user?.role == 'vendor';

    return Drawer(
      backgroundColor: ZippaColors.background,
      child: Column(
        children: [
          // 1. Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: ZippaColors.primaryGradient,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'Z',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ZippaColors.primary),
              ),
            ),
            accountName: Text(
              user?.fullName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              user?.email ?? 'user@example.com',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          // 2. Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerTile(
                  icon: Icons.person_outline_rounded,
                  label: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    navProvider.setIndex(4); // Profile is index 4 for all shells
                  },
                ),
                _DrawerTile(
                  icon: Icons.history_rounded,
                  label: isRider ? 'Delivery History' : (isVendor ? 'Store Orders' : 'Order History'),
                  onTap: () {
                    Navigator.pop(context);
                    navProvider.setIndex(1); // Orders is index 1 for all shells
                  },
                ),
                if (isVendor)
                  _DrawerTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Product Manager',
                    onTap: () {
                      Navigator.pop(context);
                      navProvider.setIndex(2); // Products is index 2 for vendors
                    },
                  ),
                _DrawerTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: isVendor ? 'Earnings & Wallet' : 'Zippa Wallet',
                  onTap: () {
                    Navigator.pop(context);
                    navProvider.setIndex(isVendor ? 3 : 2); // Wallet is 3 for vendors, 2 for others
                  },
                ),
                const Divider(indent: 20, endIndent: 20),
                _DrawerTile(
                  icon: Icons.support_agent_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support chat coming soon!')),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About Zippa',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Zippa Logistics',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.local_shipping_rounded, color: ZippaColors.primary),
                    );
                  },
                ),
                ),
              ],
            ),
          ),

          // 3. Logout Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: Colors.redAccent,
              onTap: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final nav = Navigator.of(context);
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true) {
                  await auth.logout();
                  nav.pushNamedAndRemoveUntil('/login', (r) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? ZippaColors.textPrimary, size: 24),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? ZippaColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
