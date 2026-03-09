import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';
import 'package:zippa_app/features/rider/screens/rider_edit_profile_screen.dart';

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Rider Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: ZippaColors.primary.withOpacity(0.1),
                child: Icon(Icons.delivery_dining_rounded, size: 50, color: ZippaColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.fullName ?? 'Rider', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '', style: TextStyle(color: ZippaColors.textSecondary)),
            const SizedBox(height: 32),
            _ProfileItem(
              icon: Icons.person_outline, 
              label: 'Personal Information',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiderEditProfileScreen())),
            ),
            _ProfileItem(
              icon: Icons.directions_bike_rounded, 
              label: 'Vehicle Details',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiderEditProfileScreen())),
            ),
            _ProfileItem(
              icon: Icons.account_balance_rounded, 
              label: 'Banking & Payouts',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiderEditProfileScreen())),
            ),
            _ProfileItem(icon: Icons.history_rounded, label: 'Delivery History'),
            const Divider(height: 32, indent: 24, endIndent: 24),
            _ProfileItem(
              icon: Icons.logout_rounded, 
              label: 'Logout', 
              color: Colors.red,
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
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  const _ProfileItem({required this.icon, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? ZippaColors.textPrimary),
      title: Text(label, style: TextStyle(color: color ?? ZippaColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
