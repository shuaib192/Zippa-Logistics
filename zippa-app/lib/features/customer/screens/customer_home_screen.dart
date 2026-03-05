// ============================================
// 🎓 CUSTOMER HOME SCREEN (customer_home_screen.dart)
//
// The main dashboard for CUSTOMERS.
// Shows: Recent orders, quick actions, wallet balance.
// This is a foundational screen that we'll expand with
// order placement, tracking, and history features.
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

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
              'Hello, ${user?.fullName.split(' ').first ?? 'Customer'} 👋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Where are you sending today?',
              style: TextStyle(fontSize: 13, color: ZippaColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Notification bell
          IconButton(
            icon: Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {},
          ),
          // Profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ZippaColors.primary.withValues(alpha: 0.1),
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'C',
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
            // Wallet card
            _WalletCard().animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // Quick actions
            Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _QuickAction(icon: Icons.send_rounded, label: 'Send Package', color: ZippaColors.primary, onTap: () {})),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.track_changes_rounded, label: 'Track Order', color: ZippaColors.info, onTap: () {})),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.history_rounded, label: 'History', color: ZippaColors.accent, onTap: () {})),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Recent orders section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                TextButton(onPressed: () {}, child: Text('See All')),
              ],
            ),
            
            // Empty state
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 80, color: ZippaColors.textLight),
                    const SizedBox(height: 16),
                    Text(
                      'No orders yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Send Package" to create your first delivery!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ZippaColors.textLight),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
      
      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'ZipBot'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
      
      // Floating action button for quick order
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: ZippaColors.primary,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_rounded),
        label: Text('Send Package'),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
    );
  }
}

// Wallet balance card
class _WalletCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ZippaColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ZippaColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₦0.00',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _WalletAction(icon: Icons.add, label: 'Fund'),
              const SizedBox(width: 24),
              _WalletAction(icon: Icons.arrow_upward, label: 'Send'),
              const SizedBox(width: 24),
              _WalletAction(icon: Icons.receipt_long, label: 'History'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WalletAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ZippaColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
