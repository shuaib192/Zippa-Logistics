import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/marketplace_provider.dart';
import 'package:zippa_app/features/customer/models/category_model.dart';
import 'package:zippa_app/features/customer/screens/vendor_details_screen.dart';

/// VENDOR LIST SCREEN (vendor_list_screen.dart)
/// Displays a list of vendors in a specific category (The "Mall" View)

class VendorListScreen extends StatefulWidget {
  final Category? category;

  const VendorListScreen({super.key, this.category});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MarketplaceProvider>(context, listen: false)
          .searchVendors(categoryId: widget.category?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = Provider.of<MarketplaceProvider>(context);

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: Text(widget.category?.name ?? 'All Shops', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
      ),
      body: marketplace.isLoading
          ? const Center(child: CircularProgressIndicator())
          : marketplace.searchResults.isEmpty
              ? _NoVendorsPlaceholder(categoryName: widget.category?.name ?? 'shops')
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: marketplace.searchResults.length,
                  itemBuilder: (context, index) {
                    final vendor = marketplace.searchResults[index];
                    return _VendorTile(vendor: vendor);
                  },
                ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  final dynamic vendor;
  const _VendorTile({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorDetailsScreen(vendorId: vendor['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: ZippaColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: vendor['banner_url'] != null
                          ? Image.network(vendor['banner_url'], width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                          : const Icon(Icons.store_rounded, color: ZippaColors.primary, size: 32),
                    ),
                    // Favorite Heart Icon
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Consumer<MarketplaceProvider>(
                        builder: (context, marketplace, _) {
                          final isFav = marketplace.isFavorite(vendor['id']);
                          return GestureDetector(
                            onTap: () => marketplace.toggleFavorite(vendor['id']),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                color: isFav ? Colors.pink : Colors.grey,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor['business_name'] ?? 'Shop Name',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ZippaColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor['business_address'] ?? 'Address not available',
                      style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ZippaColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoVendorsPlaceholder extends StatelessWidget {
  final String categoryName;
  const _NoVendorsPlaceholder({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_rounded, size: 80, color: ZippaColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No $categoryName stores available yet',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ZippaColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are bringing more vendors to your area soon!',
            style: TextStyle(color: ZippaColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
