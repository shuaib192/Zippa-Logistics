import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/marketplace_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/features/customer/models/product_model.dart';

/// PRODUCT DETAILS SCREEN (product_details_screen.dart)
/// Premium view for a single product with image carousel and rich info.

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    // Combine primary image and gallery
    final allImages = [
      if (widget.product.imageUrl != null) widget.product.imageUrl!,
      ...widget.product.imageUrls,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Image Carousel Header
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: ZippaColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: allImages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return Image.network(
                        allImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: ZippaColors.primary.withOpacity(0.05),
                          child: const Icon(Icons.image_not_supported_rounded, color: ZippaColors.primary, size: 50),
                        ),
                      );
                    },
                  ),
                  if (allImages.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: allImages.asMap().entries.map((entry) {
                          return Container(
                            width: _currentPage == entry.key ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentPage == entry.key ? ZippaColors.primary : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Product Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(widget.product.price),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ZippaColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description ?? 'No description available for this product.',
                    style: const TextStyle(fontSize: 16, color: ZippaColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 100), // Space for footer
                ],
              ),
            ),
          ),
        ],
      ),
      
      // 3. Cart Controls Footer
      bottomSheet: Consumer<MarketplaceProvider>(
        builder: (context, marketplace, child) {
          final quantity = marketplace.cart[widget.product.id] ?? 0;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quantity Selector
                  Container(
                    decoration: BoxDecoration(
                      color: ZippaColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 0 ? () => marketplace.removeFromCart(widget.product.id) : null,
                          icon: const Icon(Icons.remove_rounded, color: ZippaColors.primary),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => marketplace.addToCart(widget.product),
                          icon: const Icon(Icons.add_rounded, color: ZippaColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Add to Cart Button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (quantity == 0) {
                            marketplace.addToCart(widget.product);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZippaColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          quantity == 0 ? 'Add to Cart' : 'Done',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
