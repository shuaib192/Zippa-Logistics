// CATEGORY MODEL (category_model.dart)
// Represents a marketplace category (e.g., Groceries, Pharmacy).

class Category {
  final String id;
  final String name;
  final String? iconName;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.iconName,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      iconName: json['icon_name'],
      imageUrl: json['image_url'],
    );
  }
}
