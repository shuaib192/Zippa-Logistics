// ============================================
// 📦 ORDER PROVIDER (order_provider.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/data/models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _error;
  List<OrderModel> _orders = [];
  Map<String, dynamic>? _lastEstimate;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OrderModel> get orders => _orders;
  Map<String, dynamic>? get lastEstimate => _lastEstimate;

  // ============================================
  // Current Order Creation State
  // = : Clear this after order is placed
  // ============================================
  String _pickupAddress = '';
  double _pickupLat = 0.0;
  double _pickupLng = 0.0;
  
  String _dropoffAddress = '';
  double _dropoffLat = 0.0;
  double _dropoffLng = 0.0;
  
  String _packageSize = 'small';
  String _packageType = 'document';
  String _packageDescription = '';
  
  String _recipientName = '';
  String _recipientPhone = '';
  
  // Setters for Order State
  void setPickup(String address, double lat, double lng) {
    _pickupAddress = address; _pickupLat = lat; _pickupLng = lng;
    notifyListeners();
  }
  
  void setDropoff(String address, double lat, double lng) {
    _dropoffAddress = address; _dropoffLat = lat; _dropoffLng = lng;
    notifyListeners();
  }
  
  void setPackageDetails(String size, String type, String desc) {
    _packageSize = size; _packageType = type; _packageDescription = desc;
    notifyListeners();
  }
  
  void setRecipient(String name, String phone) {
    _recipientName = name; _recipientPhone = phone;
    notifyListeners();
  }
  
  void clearState() {
    _pickupAddress = ''; _pickupLat = 0.0; _pickupLng = 0.0;
    _dropoffAddress = ''; _dropoffLat = 0.0; _dropoffLng = 0.0;
    _packageSize = 'small'; _packageType = 'document'; _packageDescription = '';
    _recipientName = ''; _recipientPhone = '';
    _lastEstimate = null;
    notifyListeners();
  }

  // ============================================
  // API CALL: Estimate Fare
  // ============================================
  Future<bool> estimateFare() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/orders/estimate', {
        'pickup_lat': _pickupLat,
        'pickup_lng': _pickupLng,
        'dropoff_lat': _dropoffLat,
        'dropoff_lng': _dropoffLng,
        'package_size': _packageSize,
      });

      if (response['success'] != false) {
        _lastEstimate = response;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to get fare estimate';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // API CALL: Create Order
  // ============================================
  Future<OrderModel?> createOrder() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/orders', {
        'pickup_address': _pickupAddress,
        'pickup_lat': _pickupLat,
        'pickup_lng': _pickupLng,
        'dropoff_address': _dropoffAddress,
        'dropoff_lat': _dropoffLat,
        'dropoff_lng': _dropoffLng,
        'package_size': _packageSize,
        'package_type': _packageType,
        'package_description': _packageDescription,
        'recipient_name': _recipientName,
        'recipient_phone': _recipientPhone,
        'payment_method': 'cash', // Default for now
      });

      if (response['success'] != false && response['order'] != null) {
        final newOrder = OrderModel.fromJson(response['order']);
        _orders.insert(0, newOrder);
        _isLoading = false;
        clearState();
        notifyListeners();
        return newOrder;
      } else {
        _error = response['message'];
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Failed to place order';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ============================================
  // API CALL: Get User Orders
  // ============================================
  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;

    try {
      final response = await _apiClient.get('/orders');
      if (response['success'] != false && response['orders'] != null) {
        _orders = (response['orders'] as List)
            .map((o) => OrderModel.fromJson(o))
            .toList();
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = 'Failed to fetch orders';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
