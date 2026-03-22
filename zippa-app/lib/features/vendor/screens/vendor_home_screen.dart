// ============================================
// VENDOR HOME SCREEN — Professional, no emojis
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/features/customer/providers/wallet_provider.dart';
import 'package:zippa_app/features/vendor/providers/vendor_product_provider.dart';
import 'package:zippa_app/core/providers/navigation_provider.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';
import 'package:zippa_app/features/customer/screens/order_tracking_screen.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/core/widgets/zippa_image.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch data for vendor home
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
      Provider.of<WalletProvider>(context, listen: false).fetchBalance();
      Provider.of<VendorProductProvider>(context, listen: false).fetchMyProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    final user = Provider.of<AuthProvider>(context).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Banner Hero
          if (user?.bannerUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: ZippaImage.provider(user!.bannerUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomLeft,
                child: Text(
                  user.businessName ?? 'My Store',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          // Sales & Balance Card
          Consumer<WalletProvider>(
            builder: (context, wallet, _) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ZippaColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: ZippaColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatWithComma(wallet.balance),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _overviewItem(value: wallet.transactions.length.toString(), label: 'Transactions')),
                      Container(height: 36, width: 1, color: Colors.white24),
                      Expanded(
                        child: Consumer<OrderProvider>(
                          builder: (context, orders, _) => _overviewItem(
                            value: orders.orders.where((o) => o.status == 'delivered').length.toString(), 
                            label: 'Total Sales'
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Inventory & Store Status info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inventory Insights', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (user?.kycStatus == 'verified') ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      (user?.kycStatus == 'verified') ? Icons.verified : Icons.error_outline,
                      size: 14,
                      color: (user?.kycStatus == 'verified') ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (user?.kycStatus == 'verified') ? 'VERIFIED' : 'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: (user?.kycStatus == 'verified') ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Consumer<VendorProductProvider>(
            builder: (context, vendor, _) => Row(
              children: [
                _buildStatCard(
                  context, 
                  'Total Products', 
                  vendor.myProducts.length.toString(), 
                  Icons.inventory_2_outlined, 
                  ZippaColors.primary
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context, 
                  'Out of Stock', 
                  vendor.myProducts.where((p) => p.stockQuantity == 0).length.toString(), 
                  Icons.error_outline_rounded, 
                  Colors.red
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          if (user?.kycStatus != 'verified') ...[
            const SizedBox(height: 24),
            _buildKYCRequiredBanner(context, user?.kycStatus ?? 'unverified'),
          ],

          const SizedBox(height: 24),

          // Store Status Toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Store Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      user?.isOnline == true ? 'Online — Receiving orders' : 'Offline — Not receiving orders',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: user?.isOnline ?? false,
                  activeColor: ZippaColors.primary,
                  onChanged: (user?.kycStatus == 'verified') 
                    ? (val) async {
                        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final success = await orderProvider.toggleOnline(val);
                        if (success && mounted) {
                          await authProvider.fetchProfile(); // Refresh local user state
                        }
                      }
                    : (val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please verify your identity to open your store.')),
                        );
                      },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 24),

          const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _VendorAction(
                icon: Icons.add_box_outlined, 
                label: 'New Order', 
                color: ZippaColors.primary, 
                onTap: (user?.kycStatus == 'verified') 
                  ? () => Navigator.pushNamed(context, '/order-create')
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification required to create orders.')),
                    ),
              )),
              const SizedBox(width: 12),
              Expanded(child: _VendorAction(
                icon: Icons.inventory_2_outlined, 
                label: 'Products', 
                color: ZippaColors.info, 
                onTap: () => navProvider.setIndex(2),
              )),
            ],
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _VendorAction(
                icon: Icons.account_balance_wallet_outlined, 
                label: 'Earnings', 
                color: ZippaColors.accent, 
                onTap: () => navProvider.setIndex(3),
              )),
              const SizedBox(width: 12),
              Expanded(child: _VendorAction(
                icon: Icons.person_outline, 
                label: 'Profile', 
                color: ZippaColors.warning, 
                onTap: () => navProvider.setIndex(4),
              )),
            ],
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
              TextButton(onPressed: () => navProvider.setIndex(1), child: const Text('See All')),
            ],
          ),

          const SizedBox(height: 10),

          Consumer<OrderProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.orders.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()));
              }
              
              if (provider.orders.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Icon(Icons.inventory_2_outlined, size: 72, color: ZippaColors.textLight),
                      const SizedBox(height: 14),
                      const Text('No orders yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
                      const SizedBox(height: 6),
                      const Text('Create your first delivery order to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ZippaColors.textLight, fontSize: 13)),
                    ],
                  ),
                );
              }

              return Column(
                children: provider.orders.take(5).map((order) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ZippaColors.primary.withOpacity(0.1),
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
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
              TextButton(onPressed: () => navProvider.setIndex(2), child: const Text('Manager')),
            ],
          ),
          const SizedBox(height: 10),
          
          Consumer<VendorProductProvider>(
            builder: (context, vendor, _) {
              if (vendor.myProducts.isEmpty) return const SizedBox();
              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: vendor.myProducts.take(5).length,
                  itemBuilder: (context, index) {
                    final product = vendor.myProducts[index];
                    return Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Container(
                              height: 90,
                              width: double.infinity,
                              color: Colors.grey.shade50,
                              child: product.imageUrl != null 
                                ? ZippaImage(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.image_outlined, color: Colors.grey),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                                Text(CurrencyFormatter.formatWithComma(product.price), style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 11, color: ZippaColors.textSecondary)),
          ],
        ),
      ),
    );
  }
  Widget _buildKYCRequiredBanner(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Verification Required',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
              status == 'pending'
                ? const Text('Reviewing...', style: TextStyle(fontSize: 12, color: Colors.orange))
                : TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/kyc'),
                    child: const Text('Complete KYC'),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'You must complete your identity verification before you can open your store or receive orders.',
            style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _overviewItem({required String value, required String label}) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: ZippaColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

