// ============================================
// RIDER HOME SCREEN — Professional, no emojis
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:intl/intl.dart';

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
    final orderProvider = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName.split(' ').first ?? 'Rider'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              _isOnline ? 'Online — ready for deliveries' : 'Currently offline',
              style: TextStyle(
                fontSize: 12,
                color: _isOnline ? ZippaColors.success : ZippaColors.textSecondary,
              ),
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
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'R',
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
            // Online toggle card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _isOnline
                    ? ZippaColors.primaryGradient
                    : const LinearGradient(colors: [Color(0xFF4B5563), Color(0xFF374151)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (_isOnline ? ZippaColors.primary : Colors.grey).withValues(alpha: 0.35),
                    blurRadius: 20, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? 'You are Online' : 'You are Offline',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isOnline ? 'Waiting for delivery requests' : 'Go online to start receiving orders',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
                    child: Switch(
                      value: _isOnline,
                      onChanged: (v) {
                        setState(() => _isOnline = v);
                        if (v) {
                          orderProvider.fetchPendingOrders();
                        }
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: ZippaColors.primaryLight,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: 24),

            const Text("Today's Summary", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.monetization_on_outlined, label: 'Earnings', value: 'N0.00', color: ZippaColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.local_shipping_outlined, label: 'Deliveries', value: '0', color: ZippaColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.star_border_rounded, label: 'Rating', value: '5.0', color: ZippaColors.warning)),
              ],
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 24),

            const Text('Available Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
            const SizedBox(height: 14),

            if (_isOnline)
              orderProvider.isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
                : orderProvider.orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderProvider.orders.length,
                      itemBuilder: (context, index) {
                        final order = orderProvider.orders[index];
                        return _OrderCard(order: order, currencyFormat: currencyFormat);
                      },
                    )
            else
              _buildOfflineState(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.delivery_dining_outlined, size: 72, color: ZippaColors.textLight),
          const SizedBox(height: 14),
          const Text('No orders nearby', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
          const SizedBox(height: 6),
          const Text('We will notify you when a new delivery request is available', textAlign: TextAlign.center, style: TextStyle(color: ZippaColors.textLight, fontSize: 13)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.cloud_off_rounded, size: 72, color: ZippaColors.textLight),
          const SizedBox(height: 14),
          const Text('You are offline', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
          const SizedBox(height: 6),
          const Text('Go online to start receiving delivery requests and earning', textAlign: TextAlign.center, style: TextStyle(color: ZippaColors.textLight, fontSize: 13)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat currencyFormat;
  const _OrderCard({required this.order, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: ZippaColors.secondary, borderRadius: BorderRadius.circular(12)),
                child: Text('#${order.orderNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ZippaColors.primary)),
              ),
              const Spacer(),
              Text(currencyFormat.format(order.riderEarnings), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.success)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, size: 12, color: ZippaColors.primary),
                  Container(width: 2, height: 20, color: Colors.grey.shade200),
                  const Icon(Icons.location_on, size: 14, color: ZippaColors.error),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Text(order.dropoffAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to Order Details
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Details', style: TextStyle(fontSize: 14)),
            ),
          ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZippaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: ZippaColors.textSecondary)),
        ],
      ),
    );
  }
}
