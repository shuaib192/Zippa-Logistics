import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/vendor/providers/vendor_product_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/data/models/product_model.dart';
import 'package:zippa_app/core/widgets/zippa_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import 'package:zippa_app/features/customer/screens/product_details_screen.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends State<VendorProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VendorProductProvider>(context, listen: false);
      provider.fetchMyProducts();
      provider.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.background,
      body: Consumer<VendorProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myProducts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myProducts.length,
            itemBuilder: (context, index) {
              final product = provider.myProducts[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: ZippaColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Start adding products to your store.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade100,
                child: product.imageUrl != null 
                  ? ZippaImage(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description ?? 'No description',
                    style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        CurrencyFormatter.formatWithComma(product.price),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: ZippaColors.primary, fontSize: 16),
                      ),
                      if (product.stockQuantity > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.stockQuantity < 5 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.stockQuantity < 5 ? 'Low Stock: ${product.stockQuantity}' : 'Stock: ${product.stockQuantity}',
                            style: TextStyle(
                              color: product.stockQuantity < 5 ? Colors.orange : Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, color: ZippaColors.primary, size: 20),
                      tooltip: 'Preview as customer',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                      onPressed: () => _showEditProductDialog(product),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: product.isAvailable, 
                  activeColor: ZippaColors.success,
                  onChanged: (val) {
                    Provider.of<VendorProductProvider>(context, listen: false).updateProduct(
                      product.id, 
                      {'is_available': val}
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '10');
    String? selectedCategoryId;
    XFile? imageFile;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Text('New Product', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery, 
                      imageQuality: 60,
                      maxWidth: 800,
                      maxHeight: 800,
                    );
                    if (pickedFile != null) {
                      setDialogState(() => imageFile = pickedFile);
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: imageFile != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16), 
                        child: kIsWeb 
                          ? Image.network(imageFile!.path, fit: BoxFit.cover)
                          : Image.file(File(imageFile!.path), fit: BoxFit.cover)
                      )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Add Product Image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                  ),
                ),
                
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Fresh Milk'),
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                Consumer<VendorProductProvider>(
                  builder: (context, provider, _) => DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: provider.categories.map((cat) => DropdownMenuItem(
                      value: cat['id'].toString(),
                      child: Text(cat['name']),
                    )).toList(),
                    onChanged: (val) => selectedCategoryId = val,
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (₦)', hintText: '0.00'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock Qty', hintText: '10'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'What makes this product special?'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                      
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final provider = Provider.of<VendorProductProvider>(context, listen: false);
                      
                      String? base64Image;
                      try {
                        if (imageFile != null) {
                          final bytes = await imageFile!.readAsBytes();
                          base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        }
                      } catch (e) {
                        if (context.mounted) {
                          messenger.showSnackBar(SnackBar(content: Text('Error processing image: $e')));
                        }
                        return;
                      }

                      if (!context.mounted) return;

                      final success = await provider.addProduct({
                        'name': nameController.text.trim(),
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'description': descController.text.trim(),
                        'category_id': selectedCategoryId,
                        'image_url': base64Image,
                        'stock_quantity': int.tryParse(stockController.text) ?? 0,
                      });
                      
                      if (!context.mounted) return;
                      if (success) {
                        navigator.pop();
                        messenger.showSnackBar(const SnackBar(content: Text('Product added successfully')));
                      }
                    },
                    child: const Text('Publish Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final descController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stockQuantity.toString());
    String? selectedCategoryId = product.categoryId;
    XFile? imageFile;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Product', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product?'),
                            content: const Text('Are you sure you want to remove this product?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          if (!context.mounted) return;
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final provider = Provider.of<VendorProductProvider>(context, listen: false);

                          final success = await provider.deleteProduct(product.id);
                          if (!context.mounted) return;
                          if (success) {
                            navigator.pop(); // Close bottom sheet
                            messenger.showSnackBar(const SnackBar(content: Text('Product deleted')));
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery, 
                      imageQuality: 60,
                      maxWidth: 800,
                      maxHeight: 800,
                    );
                    if (pickedFile != null) {
                      setDialogState(() => imageFile = pickedFile);
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: imageFile != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16), 
                        child: kIsWeb 
                          ? Image.network(imageFile!.path, fit: BoxFit.cover)
                          : Image.file(File(imageFile!.path), fit: BoxFit.cover)
                      )
                      : (product.imageUrl != null 
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: ZippaImage(imageUrl: product.imageUrl!, fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Change Image', style: TextStyle(color: Colors.grey)),
                              ],
                            )),
                  ),
                ),
                
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                Consumer<VendorProductProvider>(
                  builder: (context, provider, _) => DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: provider.categories.map((cat) => DropdownMenuItem(
                      value: cat['id'].toString(),
                      child: Text(cat['name']),
                    )).toList(),
                    onChanged: (val) => selectedCategoryId = val,
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (₦)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock Qty'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                      
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final provider = Provider.of<VendorProductProvider>(context, listen: false);
                      
                      String? base64Image;
                      try {
                        if (imageFile != null) {
                          final bytes = await imageFile!.readAsBytes();
                          base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        }
                      } catch (e) {
                        if (context.mounted) {
                          messenger.showSnackBar(SnackBar(content: Text('Error processing image: $e')));
                        }
                        return;
                      }

                      if (!context.mounted) return;

                      final success = await provider.updateProduct(
                        product.id,
                        {
                          'name': nameController.text.trim(),
                          'price': double.tryParse(priceController.text) ?? 0.0,
                          'description': descController.text.trim(),
                          'category_id': selectedCategoryId,
                          'image_url': base64Image,
                          'stock_quantity': int.tryParse(stockController.text) ?? 0,
                        }
                      );
                      
                      if (!context.mounted) return;
                      if (success) {
                        navigator.pop();
                        messenger.showSnackBar(const SnackBar(content: Text('Product updated')));
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
