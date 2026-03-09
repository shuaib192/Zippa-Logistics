import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/marketplace_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/features/customer/screens/marketplace_cart_screen.dart';
import 'package:zippa_app/features/customer/screens/product_details_screen.dart';
import 'package:zippa_app/features/customer/models/product_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// VENDOR DETAILS SCREEN (vendor_details_screen.dart)
/// Displays a specific shop's profile and products (The "Shop" View)

class VendorDetailsScreen extends StatefulWidget {
  final String vendorId;

  const VendorDetailsScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  Map<String, dynamic>? _vendorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorDetails();
  }

  Future<void> _loadVendorDetails() async {
    final data = await Provider.of<MarketplaceProvider>(context, listen: false)
        .getVendorDetails(widget.vendorId);
    
    if (mounted) {
      setState(() {
        _vendorData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_vendorData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Failed to load store details')),
      );
    }

    final vendor = _vendorData!['vendor'];
    final productsData = _vendorData!['products'] as List;
    final products = productsData.map((p) => Product.fromJson(p)).toList();

    return Scaffold(
      backgroundColor: ZippaColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header with Cover Image
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: ZippaColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: vendor['banner_url'] != null
                      ? Image.network(
                          vendor['banner_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: ZippaColors.primary.withOpacity(0.1),
                            child: const Center(
                              child: Icon(Icons.store_rounded, color: ZippaColors.primary, size: 80),
                            ),
                          ),
                        )
                      : Container(
                          color: ZippaColors.primary.withOpacity(0.1),
                          child: const Center(
                            child: Icon(Icons.store_rounded, color: ZippaColors.primary, size: 80),
                          ),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {},
                  ),
                  Consumer<MarketplaceProvider>(
                    builder: (context, marketplace, _) {
                      final isFav = marketplace.isFavorite(widget.vendorId);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: isFav ? Colors.pink : Colors.white,
                        ),
                        onPressed: () => marketplace.toggleFavorite(widget.vendorId),
                      );
                    },
                  ),
                ],
              ),

              // Shop Info Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              vendor['business_name'] ?? 'Shop Name',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text('4.5', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vendor['category_name'] ?? 'Store',
                        style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: ZippaColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vendor['business_address'] ?? 'No address',
                              style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Product List Section
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Products (${products.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                  ),
                ),
              ),

              products.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text('This shop has no products yet', style: TextStyle(color: ZippaColors.textLight)),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = products[index];
                            return _ProductTile(product: product);
                          },
                          childCount: products.length,
                        ),
                      ),
                    ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // Sticky View Cart Footer
          Consumer<MarketplaceProvider>(
            builder: (context, marketplace, child) {
              if (marketplace.cartCount == 0) return const SizedBox();
              
              return Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarketplaceCartScreen(vendor: vendor),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: ZippaColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: ZippaColors.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${marketplace.cartCount}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'View Cart',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(marketplace.cartTotal),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms, curve: Curves.easeOut);
            },
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceProvider>(
      builder: (context, marketplace, child) {
        final quantity = marketplace.cart[product.id] ?? 0;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  height: 85,
                  width: 85,
                  decoration: BoxDecoration(
                    color: ZippaColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    image: product.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imageUrl == null
                      ? const Icon(Icons.inventory_2_rounded, color: ZippaColors.primary, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ZippaColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description ?? 'No description available',
                        style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: ZippaColors.primary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                
                // Quantity Controls
                if (quantity == 0)
                  IconButton(
                    onPressed: () => marketplace.addToCart(product),
                    icon: const Icon(Icons.add_circle_rounded, color: ZippaColors.primary, size: 30),
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => marketplace.removeFromCart(product.id),
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: ZippaColors.primary, size: 24),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        onPressed: () => marketplace.addToCart(product),
                        icon: const Icon(Icons.add_circle_rounded, color: ZippaColors.primary, size: 24),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
