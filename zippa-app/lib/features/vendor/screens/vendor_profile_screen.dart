import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/widgets/zippa_image.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/features/customer/screens/change_password_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Header Profile section
          GestureDetector(
            onTap: () => _showEditAvatarDialog(context, user),
            child: Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: ZippaColors.primary.withValues(alpha: 0.1),
                    child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: ZippaImage(imageUrl: user.avatarUrl, width: 100, height: 100, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.storefront_rounded, size: 50, color: ZippaColors.primary),
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
          ),
          const SizedBox(height: 16),
          Text(user?.businessName ?? user?.fullName ?? 'Vendor Store', 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.role.toUpperCase() ?? 'VENDOR', 
            style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
          
          const SizedBox(height: 32),

          // Business Section
          _buildSectionHeader('Business Verification'),
          _ProfileItem(
            icon: Icons.business_rounded, 
            label: 'Business Details',
            subtitle: user?.businessName ?? 'Not set',
            onTap: () => _showEditBusinessDialog(context, user),
          ),
          _ProfileItem(
            icon: Icons.location_on_outlined, 
            label: 'Business Address',
            subtitle: user?.businessAddress ?? 'Not set',
            onTap: () => _showEditBusinessDialog(context, user),
          ),
          _ProfileItem(
            icon: Icons.verified_user_outlined, 
            label: 'CAC / Reg Number',
            subtitle: user?.businessRegNumber ?? 'Not set',
            onTap: () => _showEditBusinessDialog(context, user),
          ),
          _ProfileItem(
            icon: Icons.image_outlined, 
            label: 'Store Banner',
            subtitle: user?.bannerUrl != null ? 'Banner uploaded' : 'No banner set',
            onTap: () => _showEditBannerDialog(context, user),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('Account & Security'),
          _ProfileItem(
            icon: Icons.person_outline, 
            label: 'Owner Information',
            subtitle: user?.fullName ?? '',
            onTap: () => _showEditOwnerDialog(context, user),
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
          
          const SizedBox(height: 16),
          _buildSectionHeader('Payout Settings'),
          _ProfileItem(
            icon: Icons.account_balance_rounded, 
            label: 'Bank Account Details',
            subtitle: (user?.payoutAccountNumber != null && user!.payoutAccountNumber!.isNotEmpty) 
                ? '${user.payoutBankName} • ${user.payoutAccountNumber}' 
                : 'Not set',
            onTap: () => _showEditPayoutDialog(context, user),
          ),
          
          const SizedBox(height: 16),
          _buildSectionHeader('Other'),
          _ProfileItem(
            icon: Icons.help_outline, 
            label: 'Help Center',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Zippa Logistics',
                applicationVersion: '1.0.0',
                children: [
                  const Text('Zippa Vendor Portal allows you to manage your store with ease.'),
                ],
              );
            },
          ),
          
          const Divider(height: 48, indent: 24, endIndent: 24),
          
          _ProfileItem(
            icon: Icons.logout_rounded, 
            label: 'Logout', 
            color: Colors.red,
            onTap: () async {
               final auth = Provider.of<AuthProvider>(context, listen: false);
               final nav = Navigator.of(context);
               final shouldLogout = await showConfirmDialog(context, 'Logout', 'Are you sure you want to logout?');
                if (shouldLogout == true) {
                  await auth.logout();
                  nav.pushNamedAndRemoveUntil('/login', (r) => false);
                }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ),
    );
  }

  void _showEditBusinessDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    final bizNameController = TextEditingController(text: user.businessName);
    final bizAddressController = TextEditingController(text: user.businessAddress);
    final bizRegController = TextEditingController(text: user.businessRegNumber);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Business Profile'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bizNameController,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bizAddressController,
                  decoration: const InputDecoration(labelText: 'Business Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bizRegController,
                  decoration: const InputDecoration(labelText: 'CAC / Registration Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setState(() => isSaving = true);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await auth.updateProfile({
                  'businessName': bizNameController.text.trim(),
                  'businessAddress': bizAddressController.text.trim(),
                  'businessRegNumber': bizRegController.text.trim(),
                });
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business profile updated!')));
                }
                if (context.mounted) setState(() => isSaving = false);
              },
              child: isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBannerDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    XFile? imageFile;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Store Banner'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add a professional banner for your store home page.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery, 
                    imageQuality: 60,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (pickedFile != null) {
                    setState(() => imageFile = pickedFile);
                  }
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: imageFile != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12), 
                        child: kIsWeb 
                          ? Image.network(imageFile!.path, fit: BoxFit.cover)
                          // Mobile only: safely use File
                          : Image.file(File(imageFile!.path), fit: BoxFit.cover),
                      )
                    : (user.bannerUrl != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: ZippaImage(imageUrl: user.bannerUrl!, fit: BoxFit.cover))
                        : const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (isSaving || imageFile == null) ? null : () async {
                setState(() => isSaving = true);
                try {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  
                  final bytes = await imageFile!.readAsBytes();
                  final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

                  final success = await auth.updateProfile({
                    'bannerUrl': base64Image,
                  });

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store banner updated!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (context.mounted) setState(() => isSaving = false);
                }
              },
              child: isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAvatarDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    XFile? imageFile;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Profile Picture'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update your professional profile picture.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery, 
                    imageQuality: 60,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (pickedFile != null) {
                    setState(() => imageFile = pickedFile);
                  }
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: user.avatarUrl != null ? ZippaImage.provider(user.avatarUrl) : null,
                  child: imageFile != null 
                      ? FutureBuilder<Uint8List>(
                          future: imageFile!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.memory(snapshot.data!, fit: BoxFit.cover, width: 100, height: 100),
                              );
                            }
                            return const CircularProgressIndicator();
                          },
                        )
                      : (user.avatarUrl != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: ZippaImage(imageUrl: user.avatarUrl!, fit: BoxFit.cover, width: 100, height: 100),
                            )
                          : const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (isSaving || imageFile == null) ? null : () async {
                setState(() => isSaving = true);
                try {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  
                  final bytes = await imageFile!.readAsBytes();
                  final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

                  final success = await auth.updateProfile({
                    'avatarUrl': base64Image,
                  });

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (context.mounted) setState(() => isSaving = false);
                }
              },
              child: isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOwnerDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Owner Info'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setState(() => isSaving = true);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await auth.updateProfile({
                  'fullName': nameController.text.trim(),
                  'email': emailController.text.trim(),
                });
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                }
                if (context.mounted) setState(() => isSaving = false);
              },
              child: isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPayoutDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    final bankNameController = TextEditingController(text: user.payoutBankName);
    final accountNumController = TextEditingController(text: user.payoutAccountNumber);
    final accountNameController = TextEditingController(text: user.payoutAccountName);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Payout Settings'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter the bank account where you want to receive your withdrawals.', 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    hintText: 'e.g. GTBank, Zenith...',
                    prefixIcon: Icon(Icons.account_balance_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accountNumController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    hintText: '10 digits',
                    prefixIcon: Icon(Icons.numbers_rounded, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'As it appears on your bank',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (accountNumController.text.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid account number')));
                  return;
                }
                setState(() => isSaving = true);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await auth.updateProfile({
                  'payoutBankName': bankNameController.text.trim(),
                  'payoutAccountNumber': accountNumController.text.trim(),
                  'payoutAccountName': accountNameController.text.trim(),
                });
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout details updated!')));
                }
                if (context.mounted) setState(() => isSaving = false);
              },
              child: isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> showConfirmDialog(BuildContext context, String title, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback? onTap;
  const _ProfileItem({required this.icon, required this.label, this.subtitle, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? ZippaColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? ZippaColors.primary, size: 20),
      ),
      title: Text(label, style: TextStyle(color: color ?? ZippaColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
