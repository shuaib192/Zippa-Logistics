// ============================================
// CUSTOMER HOME SCREEN — Professional, no emojis
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/widgets/zippa_image.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/features/customer/screens/order_tracking_screen.dart';
import 'package:zippa_app/features/customer/screens/customer_orders_screen.dart';
import 'package:zippa_app/features/customer/screens/customer_wallet_screen.dart';
import 'package:zippa_app/features/customer/screens/zipbot_screen.dart';
import 'package:zippa_app/core/providers/navigation_provider.dart';
import 'package:zippa_app/features/customer/screens/customer_profile_screen.dart';
import 'package:zippa_app/features/customer/providers/wallet_provider.dart';
import 'package:zippa_app/features/customer/providers/marketplace_provider.dart';
import 'package:zippa_app/features/customer/screens/vendor_list_screen.dart';
import 'package:zippa_app/features/customer/screens/vendor_details_screen.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';
import 'package:zippa_app/core/providers/location_provider.dart';
import 'package:zippa_app/core/services/fcm_service.dart';
import 'package:zippa_app/core/services/debug_log_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'My Orders';
      case 2: return 'My Wallet';
      case 3: return 'ZipBot AI';
      case 4: return 'Profile';
      default: return 'Zippa';
    }
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0: return const _HomeContent();
      case 1: return const CustomerOrdersScreen();
      case 2: return const CustomerWalletScreen();
      case 3: return const ZipBotScreen();
      case 4: return const CustomerProfileScreen();
      default: return const _HomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    final user = Provider.of<AuthProvider>(context).user;
    final currentIndex = navProvider.currentIndex;

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_getAppBarTitle(currentIndex), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ZippaColors.primary.withOpacity(0.12),
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'C',
                style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _getScreen(currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navProvider.currentIndex,
        onTap: (index) => navProvider.setIndex(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ZippaColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'ZipBot'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: navProvider.currentIndex == 0 
        ? FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/order-create'),
            backgroundColor: ZippaColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Send Package'),
          )
        : null,
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
      Provider.of<WalletProvider>(context, listen: false).fetchBalance();
      Provider.of<MarketplaceProvider>(context, listen: false).fetchCategories();
      Provider.of<MarketplaceProvider>(context, listen: false).fetchFeaturedVendors();
      Provider.of<MarketplaceProvider>(context, listen: false).fetchFavorites();
      
      // Request permissions sequentially to avoid dialog overlapping
      await Provider.of<LocationProvider>(context, listen: false).requestLocationPermission();
      
      // Small delay for smooth transition between prompts
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        DebugLogService.showDebugOverlay(context);
        await FCMService.syncToken();
        await FCMService.subscribeToTopic('customers');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = Provider.of<MarketplaceProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WalletCard(),
          const SizedBox(height: 16),

          // KYC Banner
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final status = auth.user?.kycStatus ?? 'unverified';
              if (status == 'verified') return const SizedBox.shrink();
              
              final isPending = status == 'pending';
              final isRejected = status == 'rejected';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isRejected ? Colors.red : ZippaColors.primary).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (isRejected ? Colors.red : ZippaColors.primary).withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPending ? Icons.hourglass_top_rounded : (isRejected ? Icons.error_outline : Icons.info_outline), 
                      color: isRejected ? Colors.red : ZippaColors.primary, 
                      size: 24
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPending ? 'Identity Verification Pending' : (isRejected ? 'Identification Rejected' : 'Verify Your Identity'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isRejected ? Colors.red : ZippaColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPending 
                              ? 'Your documents are currently being reviewed by our team.' 
                              : (isRejected ? 'There was an issue with your documents. Please resubmit.' : 'Complete your KYC verification to access all features.'),
                            style: const TextStyle(fontSize: 11, color: ZippaColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (!isPending)
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/kyc-submit'),
                        child: Text(isRejected ? 'Resubmit' : 'Verify', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 50.ms).slideX(begin: 0.1, end: 0);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Safety & Escrow Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ZippaColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZippaColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: ZippaColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Secure Escrow Payments',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZippaColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Funds are held safely and only released when you confirm delivery.',
                        style: TextStyle(fontSize: 11, color: ZippaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Marketplace Categories
          const Text('Marketplace', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: marketplace.isLoading && marketplace.categories.isEmpty
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: marketplace.categories.length,
                  itemBuilder: (context, index) {
                    final category = marketplace.categories[index];
                    return _CategoryItem(category: category);
                  },
                ),
          ),
          
          const SizedBox(height: 24),

          // Favorite Stores
          if (marketplace.favorites.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Favorites', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: marketplace.favorites.length,
                itemBuilder: (context, index) {
                  final vendor = marketplace.favorites[index];
                  return _FavoriteVendorCard(vendor: vendor);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _QuickAction(icon: Icons.send_rounded, label: 'Send Package', color: ZippaColors.primary, onTap: () => Navigator.pushNamed(context, '/order-create'))),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(
                icon: Icons.track_changes_rounded, 
                label: 'Track Order', 
                color: ZippaColors.info, 
                onTap: () {
                  final provider = Provider.of<OrderProvider>(context, listen: false);
                  if (provider.orders.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(orderId: provider.orders.first.id ?? ''),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No active orders to track.')),
                    );
                  }
                }
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(
                icon: Icons.history_rounded, 
                label: 'History', 
                color: ZippaColors.accent, 
                onTap: () => Provider.of<NavigationProvider>(context, listen: false).setIndex(1),
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Featured Vendors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Shops', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
              TextButton(onPressed: () {}, child: const Text('See All')),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: marketplace.featuredVendors.isEmpty
              ? _NoVendorsPlaceholder()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: marketplace.featuredVendors.length,
                  itemBuilder: (context, index) {
                    final vendor = marketplace.featuredVendors[index];
                    return _VendorCard(vendor: vendor);
                  },
                ),
          ),
          
          const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                TextButton(
                  onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setIndex(1), 
                  child: const Text('See All'),
                ),
              ],
            ),
            Consumer<OrderProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.orders.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()));
                }
                
                if (provider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.local_shipping_outlined, size: 72, color: ZippaColors.textLight),
                        const SizedBox(height: 14),
                        const Text('No orders yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
                        const SizedBox(height: 6),
                        const Text('Tap "Send Package" to create\nyour first delivery',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ZippaColors.textLight, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: provider.orders.take(3).map((order) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ZippaColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: ZippaColors.primary, size: 20),
                    ),
                    title: Text('Order #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(order.status[0].toUpperCase() + order.status.substring(1), 
                      style: TextStyle(fontSize: 12, color: order.status == 'delivered' ? ZippaColors.success : ZippaColors.warning)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingScreen(orderId: order.id ?? ''),
                        ),
                      );
                    },
                  )).toList(),
                );
              },
            ),
          ],
        ),
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
          Consumer<WalletProvider>(
            builder: (context, wallet, _) => Text(
              CurrencyFormatter.formatWithComma(wallet.balance),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _WalletAction(icon: Icons.add, label: 'Fund', onTap: () => Provider.of<NavigationProvider>(context, listen: false).setIndex(2)),
              const SizedBox(width: 28),
              _WalletAction(icon: Icons.arrow_upward, label: 'Send', onTap: () => Navigator.pushNamed(context, '/order-create')),
              const SizedBox(width: 28),
              _WalletAction(icon: Icons.receipt_long_rounded, label: 'History', onTap: () => Provider.of<NavigationProvider>(context, listen: false).setIndex(2)),
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
  final VoidCallback? onTap;
  const _WalletAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
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

class _CategoryItem extends StatelessWidget {
  final dynamic category;
  const _CategoryItem({required this.category});

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'shopping_basket_rounded': return Icons.shopping_basket_rounded;
      case 'medical_services_rounded': return Icons.medical_services_rounded;
      case 'restaurant_rounded': return Icons.restaurant_rounded;
      case 'devices_rounded': return Icons.devices_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VendorListScreen(category: category)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ZippaColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_getIcon(category.iconName), color: ZippaColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ZippaColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final dynamic vendor;
  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VendorDetailsScreen(vendorId: vendor['id'])),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: vendor['banner_url'] != null && vendor['banner_url'].toString().isNotEmpty
                ? ZippaImage(
                    imageUrl: vendor['banner_url'],
                    width: double.infinity,
                    height: 90,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 90,
                    width: double.infinity,
                    color: ZippaColors.primary.withOpacity(0.05),
                    child: const Icon(Icons.store_rounded, color: ZippaColors.primary, size: 40),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor['business_name'] ?? 'Shop Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor['category_name'] ?? 'Store',
                    style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoVendorsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ZippaColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('No shops available nearby yet', style: TextStyle(color: ZippaColors.textLight, fontSize: 13)),
      ),
    );
  }
}

class _FavoriteVendorCard extends StatelessWidget {
  final dynamic vendor;
  const _FavoriteVendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VendorDetailsScreen(vendorId: vendor['id'])),
              );
            },
            child: Stack(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ZippaColors.primary.withOpacity(0.1), width: 3),
                    image: DecorationImage(
                      image: (vendor['avatar_url'] != null && vendor['avatar_url'].toString().startsWith('http'))
                        ? NetworkImage(vendor['avatar_url'])
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_rounded, color: Colors.pink, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vendor['business_name'] ?? 'Shop',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ProductSearchScreen extends StatelessWidget {
  final String query;
  const ProductSearchScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "$query"'),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<MarketplaceProvider>(
        builder: (context, marketplace, _) {
          if (marketplace.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (marketplace.productSearchResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Try searching for something else', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: marketplace.productSearchResults.length,
            itemBuilder: (context, index) {
              final product = marketplace.productSearchResults[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60, height: 60, color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    CurrencyFormatter.formatWithComma(product.price),
                    style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => marketplace.addToCart(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZippaColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Add', style: TextStyle(fontSize: 12)),
                  ),
                  onTap: () {
                    // Navigate to VendorDetailsScreen or ProductDetails
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VendorDetailsScreen(vendorId: product.vendorId)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
