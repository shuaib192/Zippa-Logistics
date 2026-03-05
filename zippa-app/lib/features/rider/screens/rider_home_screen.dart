// ============================================
// 🎓 RIDER HOME SCREEN (rider_home_screen.dart)
//
// Dashboard for RIDERS (delivery partners).
// Shows: Online/offline toggle, today's earnings,
// delivery stats, and incoming order requests.
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  bool _isOnline = false;

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
              'Hey, ${user?.fullName.split(' ').first ?? 'Rider'} 🏍️',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              _isOnline ? 'You\'re online — ready for deliveries!' : 'You\'re offline',
              style: TextStyle(fontSize: 13, color: _isOnline ? ZippaColors.success : ZippaColors.textSecondary),
            ),
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
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'R',
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
            // Online/Offline toggle card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _isOnline ? ZippaColors.primaryGradient : LinearGradient(
                  colors: [Colors.grey.shade600, Colors.grey.shade800],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: (_isOnline ? ZippaColors.primary : Colors.grey).withValues(alpha: 0.4),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isOnline ? 'You\'re Online' : 'You\'re Offline',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_isOnline ? 'Waiting for delivery requests...' : 'Go online to start receiving orders',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.3,
                    child: Switch(
                      value: _isOnline,
                      onChanged: (value) => setState(() => _isOnline = value),
                      activeThumbColor: Colors.white,
                      activeTrackColor: ZippaColors.primaryLight,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // Earnings summary
            Text('Today\'s Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.monetization_on, label: 'Earnings', value: '₦0.00', color: ZippaColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.local_shipping, label: 'Deliveries', value: '0', color: ZippaColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.star, label: 'Rating', value: '5.0', color: ZippaColors.warning)),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Active deliveries
            Text('Active Deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.delivery_dining_outlined, size: 80, color: ZippaColors.textLight),
                    const SizedBox(height: 16),
                    Text('No active deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(_isOnline ? 'New delivery requests will appear here' : 'Go online to receive delivery requests',
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
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'ZipBot'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZippaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: ZippaColors.textSecondary)),
        ],
      ),
    );
  }
}
