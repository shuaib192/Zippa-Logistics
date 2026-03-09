import 'package:flutter/material.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/features/customer/models/category_model.dart';
import 'package:zippa_app/features/customer/models/product_model.dart';

/// MARKETPLACE PROVIDER (marketplace_provider.dart)
/// Manages state for categories, vendors, products, favorites, and cart.

class MarketplaceProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Category> _categories = [];
  List<dynamic> _featuredVendors = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _favorites = [];
  List<Product> _productSearchResults = [];
  bool _isLoading = false;
  String? _customerNotes;

  // Getters
  List<Category> get categories => _categories;
  List<dynamic> get featuredVendors => _featuredVendors;
  List<dynamic> get searchResults => _searchResults;
  List<dynamic> get favorites => _favorites;
  List<Product> get productSearchResults => _productSearchResults;
  bool get isLoading => _isLoading;
  String? get customerNotes => _customerNotes;

  // Cart State
  final Map<String, int> _cart = {}; // productId -> quantity
  final Map<String, Product> _cartProductDetails = {}; // productId -> Product info

  // Cart Getters
  Map<String, int> get cart => _cart;
  Map<String, Product> get cartProductDetails => _cartProductDetails;
  int get cartCount => _cart.values.fold(0, (sum, q) => sum + q);
  double get cartTotal {
    double total = 0;
    _cart.forEach((id, q) {
      final product = _cartProductDetails[id];
      if (product != null) total += product.price * q;
    });
    return total;
  }

  String? get cartVendorId {
    if (_cartProductDetails.isEmpty) return null;
    return _cartProductDetails.values.first.vendorId;
  }

  // Methods
  void updateNotes(String? notes) {
    _customerNotes = notes;
    notifyListeners();
  }

  // Cart Methods
  void addToCart(Product product) {
    // Glovo-style rule: Only one vendor per order
    if (_cartProductDetails.isNotEmpty && _cartProductDetails.values.first.vendorId != product.vendorId) {
      _cart.clear();
      _cartProductDetails.clear();
      _customerNotes = null;
    }

    _cartProductDetails[product.id] = product;
    _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (_cart.containsKey(productId)) {
      if (_cart[productId]! > 1) {
        _cart[productId] = _cart[productId]! - 1;
      } else {
        _cart.remove(productId);
        _cartProductDetails.remove(productId);
        if (_cart.isEmpty) _customerNotes = null;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _cartProductDetails.clear();
    _customerNotes = null;
    notifyListeners();
  }

  // 1. Fetch Categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/vendors/categories', auth: false);
      if (response['success'] != false && response['categories'] != null) {
        _categories = (response['categories'] as List)
            .map((item) => Category.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Fetch categories error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Fetch Featured Vendors
  Future<void> fetchFeaturedVendors() async {
    try {
      final response = await _apiClient.get('/vendors/featured', auth: false);
      if (response['success'] != false && response['vendors'] != null) {
        _featuredVendors = response['vendors'];
      }
    } catch (e) {
      debugPrint('Fetch featured vendors error: $e');
    } finally {
      notifyListeners();
    }
  }

  // 3. Search Vendors
  Future<void> searchVendors({String? categoryId, String? query}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String endpoint = '/vendors/search?';
      if (categoryId != null) endpoint += 'category_id=$categoryId&';
      if (query != null) endpoint += 'query=$query';

      final response = await _apiClient.get(endpoint, auth: false);
      if (response['success'] != false && response['vendors'] != null) {
        _searchResults = response['vendors'];
      }
    } catch (e) {
      debugPrint('Search vendors error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Get Vendor Details
  Future<Map<String, dynamic>?> getVendorDetails(String vendorId) async {
    try {
      final response = await _apiClient.get('/vendors/$vendorId', auth: false);
      if (response['success'] != false) {
        return response;
      }
    } catch (e) {
      debugPrint('Get vendor details error: $e');
    }
    return null;
  }

  // 5. Fetch Favorites
  Future<void> fetchFavorites() async {
    try {
      final response = await _apiClient.get('/vendors/favorites/list');
      if (response['success'] != false && response['vendors'] != null) {
        _favorites = response['vendors'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch favorites error: $e');
    }
  }

  // 6. Toggle Favorite
  Future<bool> toggleFavorite(String vendorId) async {
    try {
      final response = await _apiClient.post('/vendors/favorites', {'vendor_id': vendorId});
      if (response['success'] != false) {
        await fetchFavorites(); // Refresh list
        return response['is_favorite'] ?? false;
      }
    } catch (e) {
      debugPrint('Toggle favorite error: $e');
    }
    return false;
  }

  // 7. Global Product Search
  Future<void> searchProducts(String query) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/vendors/search-products?query=$query', auth: false);
      if (response['success'] != false && response['products'] != null) {
        _productSearchResults = (response['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Global product search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(String vendorId) {
    return _favorites.any((v) => v['id'] == vendorId);
  }
}
