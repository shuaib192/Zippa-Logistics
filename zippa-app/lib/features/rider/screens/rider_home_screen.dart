import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/data/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:zippa_app/features/rider/screens/rider_deliveries_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zippa_app/features/customer/screens/zipbot_screen.dart';
import 'package:zippa_app/features/rider/screens/rider_profile_screen.dart';
import 'package:zippa_app/core/providers/navigation_provider.dart';
import 'package:zippa_app/features/customer/providers/wallet_provider.dart';
import 'package:zippa_app/core/providers/location_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/features/rider/screens/rider_order_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';
import 'package:zippa_app/features/rider/screens/rider_wallet_screen.dart';
import 'package:zippa_app/core/services/fcm_service.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {

  final List<Widget> _screens = [
    const _RiderHomeContent(),
    const RiderDeliveriesScreen(),
    Scaffold(
      appBar: AppBar(
        title: const Text('ZipBot AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: const ZipBotScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      drawer: AppDrawer(),
      body: IndexedStack(
        index: navProvider.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navProvider.currentIndex,
        onTap: (index) => navProvider.setIndex(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ZippaColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_rounded), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'ZipBot'),
        ],
      ),
    );
  }
}

class _RiderHomeContent extends StatefulWidget {
  const _RiderHomeContent();

  @override
  State<_RiderHomeContent> createState() => _RiderHomeContentState();
}

class _RiderHomeContentState extends State<_RiderHomeContent> {
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WalletProvider>(context, listen: false).fetchBalance();
        
        // Sequence permissions and topic subscription
        Future.delayed(const Duration(milliseconds: 1000), () async {
          if (mounted) {
            await FCMService.syncToken();
            await FCMService.subscribeToTopic('riders');
          }
        });
      }
    });
  }

  Future<void> _loadOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOnline = prefs.getBool('rider_online_status') ?? false;
    });
    // Sync with backend on load
    if (mounted) {
      Provider.of<OrderProvider>(context, listen: false).toggleOnline(_isOnline);
      if (_isOnline) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders();
        Provider.of<LocationProvider>(context, listen: false).startRiderTracking();
      }
    }
  }

  Future<void> _toggleOnline(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isOnline = value);
    await prefs.setBool('rider_online_status', value);
    
    if (mounted) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await orderProvider.toggleOnline(value);
      if (value) {
        orderProvider.fetchOrders();
        locationProvider.startRiderTracking();
      } else {
        locationProvider.stopTracking();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final orderProvider = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Scaffold(
      backgroundColor: ZippaColors.background,
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName.split(' ').first ?? 'Rider'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _isOnline ? 'Online — ready for deliveries' : 'Currently offline',
              style: TextStyle(
                fontSize: 11,
                color: _isOnline ? ZippaColors.success : ZippaColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiderProfileScreen())),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: ZippaColors.primary.withOpacity(0.12),
                child: Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'R',
                  style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold),
                ),
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
                    color: (_isOnline ? ZippaColors.primary : Colors.grey).withOpacity(0.35),
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
                      onChanged: _toggleOnline,
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

            const SizedBox(height: 24),
            
            // Earnings Dashboard Card (New Location)
            Consumer<WalletProvider>(
              builder: (context, wallet, child) {
                final summary = wallet.summary ?? {};
                final todayEarnings = double.tryParse(summary['today_earnings']?.toString() ?? '0') ?? 0;
                final todayDeliveries = summary['today_deliveries'] ?? 0;

                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiderWalletScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Wallet Balance', style: TextStyle(color: ZippaColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(CurrencyFormatter.formatWithComma(wallet.balance), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: ZippaColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: ZippaColors.primary),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Today's Earnings", style: TextStyle(color: ZippaColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(CurrencyFormatter.formatWithComma(todayEarnings), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade100),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Deliveries", style: TextStyle(color: ZippaColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(todayDeliveries.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiderWalletScreen(showWithdrawDialog: true))),
                            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                            label: const Text('Withdraw Funds', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ZippaColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),


            const SizedBox(height: 24),

            if (orderProvider.activeOrder != null) ...[
              _ActiveDeliveryCard(order: orderProvider.activeOrder!, currencyFormat: currencyFormat),
              const SizedBox(height: 24),
            ],

            Text('Available Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
            const SizedBox(height: 14),

            if (_isOnline)
              orderProvider.isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
                : orderProvider.orders.where((o) => o.status == 'pending').isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderProvider.orders.where((o) => o.status == 'pending').length,
                      itemBuilder: (context, index) {
                        final order = orderProvider.orders.where((o) => o.status == 'pending').toList()[index];
                        return _OrderCard(order: order, currencyFormat: currencyFormat);
                      },
                    )
            else
              _buildOfflineState(),
          ],
        ),
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
                decoration: BoxDecoration(
                  color: order.isMarketplace ? ZippaColors.primary.withOpacity(0.1) : ZippaColors.secondary,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (order.isMarketplace) ...[
                      const Icon(Icons.shopping_bag_outlined, size: 10, color: ZippaColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      order.isMarketplace ? 'MARKETPLACE' : '#${order.orderNumber}', 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: order.isMarketplace ? ZippaColors.primary : ZippaColors.primary
                      )
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(currencyFormat.format(order.riderEarnings), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.success)),
            ],
          ),
          if (order.isMarketplace) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 14, color: ZippaColors.textSecondary),
                const SizedBox(width: 6),
                Text(order.vendorName ?? 'Marketplace Store', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ZippaColors.textPrimary)),
              ],
            ),
          ],
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RiderOrderDetailsScreen(orderId: order.id!)),
                );
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



class _ActiveDeliveryCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat currencyFormat;
  const _ActiveDeliveryCard({required this.order, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ZippaColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: ZippaColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                   Icon(Icons.directions_bike, color: Colors.white, size: 18),
                   SizedBox(width: 8),
                   Text('ACTIVE DELIVERY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: Text('#${order.orderNumber}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DROPOFF LOCATION', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(order.dropoffAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EARNING', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(currencyFormat.format(order.riderEarnings), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RiderOrderDetailsScreen(orderId: order.id!)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ZippaColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Resume Task', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => launchUrl(Uri.parse('tel:${order.recipientPhone}')),
                icon: const Icon(Icons.phone),
                style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn();
  }
}
