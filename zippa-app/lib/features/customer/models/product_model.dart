/**
 * PRODUCT MODEL (product_model.dart)
 * Represents a listing from a vendor.
 */

class Product {
  final String id;
  final String vendorId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String> imageUrls;
  final bool isAvailable;
  final int stockQuantity;

  Product({
    required this.id,
    required this.vendorId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.imageUrls = const [],
    this.isAvailable = true,
    this.stockQuantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      vendorId: json['vendor_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'],
      imageUrls: json['image_urls'] != null 
        ? List<String>.from(json['image_urls']) 
        : [],
      isAvailable: json['is_available'] ?? true,
      stockQuantity: json['stock_quantity'] ?? 0,
    );
  }
}
