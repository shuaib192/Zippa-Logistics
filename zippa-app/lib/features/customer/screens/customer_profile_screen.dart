import 'package:flutter/material.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'change_password_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: ZippaColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, size: 50, color: ZippaColors.primary),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: ZippaColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Guest User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: const TextStyle(color: ZippaColors.textSecondary)),
          const SizedBox(height: 32),
          _ProfileItem(
            icon: Icons.person_outline, 
            label: 'Edit Profile',
            onTap: () => _showEditProfileDialog(context, user),
          ),
          _ProfileItem(
            icon: Icons.notifications_none, 
            label: 'Notifications',
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          _ProfileItem(
            icon: Icons.security_outlined, 
            label: 'Security & Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          if (Provider.of<AuthProvider>(context).isBiometricAvailable)
            _ProfileSwitchItem(
              icon: Icons.fingerprint_rounded,
              label: 'Biometric Unlock',
              value: Provider.of<AuthProvider>(context).isBiometricEnabled,
              onChanged: (val) {
                Provider.of<AuthProvider>(context, listen: false).toggleBiometric(val);
              },
            ),
          _ProfileItem(
            icon: Icons.help_outline, 
            label: 'Help Center',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Zippa Logistics',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(),
                children: [
                  const Text('Zippa is your premium logistics partner in Nigeria.'),
                  const SizedBox(height: 8),
                  const Text('For support, contact: support@zippalogistics.com'),
                ],
              );
            },
          ),
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
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setState(() => isSaving = true);
                try {
                  final apiClient = ApiClient();
                  final response = await apiClient.put('/users/profile', {
                    'fullName': nameController.text,
                    'email': emailController.text,
                  });
                  
                  if (response['success'] != false) {
                    if (context.mounted) {
                      await Provider.of<AuthProvider>(context, listen: false).fetchProfile();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully!')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Edit profile error: $e');
                } finally {
                  if (context.mounted) setState(() => isSaving = false);
                }
              },
              child: isSaving 
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
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
      leading: Icon(icon, color: color ?? ZippaColors.primary),
      title: Text(label, style: TextStyle(color: color ?? ZippaColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

class _ProfileSwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProfileSwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ZippaColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: ZippaColors.primary,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
