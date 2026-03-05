// ============================================
// 🎓 VENDOR HOME SCREEN (vendor_home_screen.dart)
//
// Dashboard for VENDORS (business owners).
// Shows: Today's orders overview, quick stats,
// and actions to create new deliveries.
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class VendorHomeScreen extends StatelessWidget {
  const VendorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName.split(' ').first ?? 'Vendor'} 🏪',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text('Manage your deliveries',
              style: TextStyle(fontSize: 13, color: ZippaColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications_outlined), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ZippaColors.primary.withValues(alpha: 0.1),
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'V',
                style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats overview
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ZippaColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: ZippaColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Overview', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _OverviewItem(value: '0', label: 'Pending')),
                      Container(height: 40, width: 1, color: Colors.white24),
                      Expanded(child: _OverviewItem(value: '0', label: 'In Transit')),
                      Container(height: 40, width: 1, color: Colors.white24),
                      Expanded(child: _OverviewItem(value: '0', label: 'Delivered')),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // Quick actions
            Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _VendorAction(icon: Icons.add_box_rounded, label: 'New Order', color: ZippaColors.primary, onTap: () {})),
                const SizedBox(width: 12),
                Expanded(child: _VendorAction(icon: Icons.upload_file_rounded, label: 'Bulk Upload', color: ZippaColors.info, onTap: () {})),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _VendorAction(icon: Icons.analytics_rounded, label: 'Analytics', color: ZippaColors.accent, onTap: () {})),
                const SizedBox(width: 12),
                Expanded(child: _VendorAction(icon: Icons.map_rounded, label: 'Track All', color: ZippaColors.warning, onTap: () {})),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Recent orders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: Text('See All')),
              ],
            ),
            
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 80, color: ZippaColors.textLight),
                    const SizedBox(height: 16),
                    Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Create your first delivery order to get started!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ZippaColors.textLight)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'ZipBot'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: ZippaColors.primary,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_rounded),
        label: Text('New Order'),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String value;
  final String label;
  const _OverviewItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _VendorAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _VendorAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: ZippaColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
