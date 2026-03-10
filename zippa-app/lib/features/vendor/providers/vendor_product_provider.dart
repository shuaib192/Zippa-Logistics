import 'package:flutter/material.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/data/models/product_model.dart';

class VendorProductProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  
  List<Product> _myProducts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;
  
  List<Product> get myProducts => _myProducts;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchMyProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/products/my-products');
      if (response['success'] == true) {
        final List data = response['products'] ?? [];
        _myProducts = data.map((json) => Product.fromJson(json)).toList();
      } else {
        _error = response['message'] ?? 'Failed to fetch products';
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _api.get('/vendors/categories');
      if (response['success'] == true) {
        _categories = List<Map<String, dynamic>>.from(response['categories'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }
  
  Future<bool> addProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _api.post('/products', productData);
      if (response['success'] == true) {
        await fetchMyProducts();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to add product';
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateProduct(String id, Map<String, dynamic> updateData) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _api.put('/products/$id', updateData);
      if (response['success'] == true) {
        await fetchMyProducts();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update product';
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _api.delete('/products/$id');
      if (response['success'] == true) {
        _myProducts.removeWhere((p) => p.id == id);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete product';
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
