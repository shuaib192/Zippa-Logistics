import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/features/rider/screens/rider_edit_profile_screen.dart';
import 'package:zippa_app/core/widgets/profile_switch_item.dart';

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // 1. Premium Hero Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: ZippaColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Abstract Background Patterns
                    Positioned(
                      top: -50,
                      right: -50,
                      child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.03)),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 40,
                      child: CircleAvatar(radius: 40, backgroundColor: ZippaColors.primary.withOpacity(0.05)),
                    ),
                    
                    // Profile Info
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: ZippaColors.primary.withOpacity(0.1),
                                  child: Text(
                                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'R',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: ZippaColors.success, shape: BoxShape.circle),
                                  child: const Icon(Icons.verified, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.fullName ?? 'Rider Name',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          Text(
                            user?.email ?? 'rider@zippa.com',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      _StatCard(label: 'Rides', value: '482', icon: Icons.directions_bike_rounded, color: ZippaColors.primary),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Rating', value: '4.8', icon: Icons.star_rounded, color: ZippaColors.secondary),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Level', value: 'Pro', icon: Icons.workspace_premium_rounded, color: ZippaColors.success),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Account Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                  const SizedBox(height: 12),

                  // Menu Items in Cards
                  _buildMenuCard([
                    _ProfileMenuTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      subtitle: 'Manage your profile details',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiderEditProfileScreen())),
                    ),
                    _ProfileMenuTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                    if (Provider.of<AuthProvider>(context).isBiometricAvailable)
                      ProfileSwitchItem(
                        icon: Icons.fingerprint_rounded,
                        label: 'Biometric Unlock',
                        value: Provider.of<AuthProvider>(context).isBiometricEnabled,
                        onChanged: (val) {
                          Provider.of<AuthProvider>(context, listen: false).toggleBiometric(val);
                        },
                      ),
                  ]),

                  const SizedBox(height: 20),
                  const Text('Business & Logistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                  const SizedBox(height: 12),

                  _buildMenuCard([
                    _ProfileMenuTile(
                      icon: Icons.sports_motorsports_outlined,
                      title: 'Vehicle Details',
                      subtitle: 'Motorcycle • ABC-123-XY',
                      onTap: () {},
                    ),
                    _ProfileMenuTile(
                      icon: Icons.account_balance_outlined,
                      title: 'Banking & Payouts',
                      onTap: () {},
                    ),
                    _ProfileMenuTile(
                      icon: Icons.history_rounded,
                      title: 'Delivery Reports',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 20),
                  _buildMenuCard([
                    _ProfileMenuTile(
                      icon: Icons.settings_outlined,
                      title: 'App Settings',
                      onTap: () {},
                    ),
                    _ProfileMenuTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Support & FAQ',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 32),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          if (index == children.length - 1) return children[index];
          return Column(
            children: [
              children[index],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: Colors.grey.shade50),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nav = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
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
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 10, color: ZippaColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: ZippaColors.textPrimary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ZippaColors.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: ZippaColors.textSecondary)) : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
