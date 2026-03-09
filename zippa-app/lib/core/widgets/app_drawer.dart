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
                    navProvider.setIndex(4); // Profile is index 4
                  },
                ),
                _DrawerTile(
                  icon: Icons.history_rounded,
                  label: isRider ? 'Delivery History' : 'Order History',
                  onTap: () {
                    Navigator.pop(context);
                    navProvider.setIndex(1); // Orders/Deliveries is index 1
                  },
                ),
                _DrawerTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Zippa Wallet',
                  onTap: () {
                    Navigator.pop(context);
                    navProvider.setIndex(2); // Wallet index 2
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
                const Divider(indent: 20, endIndent: 20),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                  title: const Text(
                    'Book on WhatsApp',
                    style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri whatsappUri = Uri.parse("https://wa.me/${AppConstants.whatsappNumber}?text=Hello ZipBot, I want to send a package.");
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                    }
                  },
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
