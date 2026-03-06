// ============================================
// CUSTOMER HOME SCREEN — Professional, no emojis
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
              'Hello, ${user?.fullName.split(' ').first ?? 'Customer'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Where are you sending today?',
              style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ZippaColors.primary.withValues(alpha: 0.12),
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'C',
                style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold),
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
            _WalletCard().animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 24),
            const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _QuickAction(icon: Icons.send_rounded, label: 'Send Package', color: ZippaColors.primary, onTap: () => Navigator.pushNamed(context, '/order-create'))),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.track_changes_rounded, label: 'Track Order', color: ZippaColors.info, onTap: () {})),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.history_rounded, label: 'History', color: ZippaColors.accent, onTap: () {})),
              ],
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 72, color: ZippaColors.textLight),
                  const SizedBox(height: 14),
                  const Text('No orders yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
                  const SizedBox(height: 6),
                  const Text('Tap "Send Package" to create\nyour first delivery',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ZippaColors.textLight, fontSize: 13)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/order-create'),
        backgroundColor: ZippaColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Send Package'),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
    );
  }
}

class _WalletCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ZippaColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: ZippaColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text('N0.00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          Row(
            children: [
              _WalletAction(icon: Icons.add, label: 'Fund'),
              const SizedBox(width: 28),
              _WalletAction(icon: Icons.arrow_upward, label: 'Send'),
              const SizedBox(width: 28),
              _WalletAction(icon: Icons.receipt_long_rounded, label: 'History'),
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
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ZippaColors.textPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
