// ============================================
// 🎓 AUTH PROVIDER (auth_provider.dart)
//
// WHAT IS A PROVIDER?
// Provider is Flutter's state management solution.
// "State" = data that changes over time (is user logged in? what's their name?)
//
// The problem: When user logs in on the Login screen, the Home screen
// needs to know about it. How do screens share data?
// 
// The solution: Provider! It's a "data store" that sits ABOVE all screens.
// Any screen can READ from it or WRITE to it. When data changes,
// all screens that use it automatically update.
//
// Think of it like a bulletin board in an office:
// - HR posts "New employee: John" (Provider updates)
// - All departments see the update (screens rebuild)
//
// ChangeNotifier = a class that can tell listeners "Hey, I changed!"
// notifyListeners() = the method that triggers the update
// ============================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/core/constants/app_constants.dart';
import 'package:zippa_app/core/services/fcm_service.dart';

// User model — represents a logged-in user
class User {
  final String id;
  final String? email;
  final String phone;
  final String fullName;
  final String role;
  final String kycStatus;
  final bool isOnline;
  final String? avatarUrl;
  
  // Rider-specific fields
  final String? vehicleType;
  final String? vehiclePlate;
  final String? payoutBankName;
  final String? payoutAccountNumber;
  final String? payoutAccountName;
  final String? bannerUrl;
  
  // Vendor-specific fields
  final String? businessName;
  final String? businessAddress;
  final String? businessRegNumber;
  final String? defaultPickupAddress;
  
  User({
    required this.id,
    this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.kycStatus,
    this.isOnline = false,
    this.avatarUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.payoutBankName,
    this.payoutAccountNumber,
    this.payoutAccountName,
    this.bannerUrl,
    this.businessName,
    this.businessAddress,
    this.businessRegNumber,
    this.defaultPickupAddress,
  });
  
  // Factory constructor — creates a User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    // Backend returns nested profile for some endpoints, flat for others
    final profile = json['profile'] ?? {};
    
    return User(
      id: json['id'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      role: json['role'] ?? 'customer',
      kycStatus: json['kycStatus'] ?? json['kyc_status'] ?? 'unverified',
      isOnline: json['isOnline'] ?? json['is_online'] ?? false,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      vehicleType: json['vehicle_type'] ?? profile['vehicleType'],
      vehiclePlate: json['vehicle_plate'] ?? profile['vehiclePlate'],
      payoutBankName: json['payout_bank_name'] ?? profile['payoutBankName'],
      payoutAccountNumber: json['payout_account_number'] ?? profile['payoutAccountNumber'],
      payoutAccountName: json['payout_account_name'] ?? profile['payoutAccountName'],
      bannerUrl: json['banner_url'] ?? profile['bannerUrl'],
      businessName: json['business_name'] ?? profile['businessName'],
      businessAddress: json['business_address'] ?? profile['businessAddress'],
      businessRegNumber: json['business_reg_number'] ?? profile['businessRegNumber'],
      defaultPickupAddress: json['default_pickup_address'] ?? profile['defaultPickupAddress'],
    );
  }
  
  // Convert User to JSON (for storing locally)
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role,
    'kycStatus': kycStatus,
    'isOnline': isOnline,
    'avatar_url': avatarUrl,
    'vehicle_type': vehicleType,
    'vehicle_plate': vehiclePlate,
    'payout_bank_name': payoutBankName,
    'payout_account_number': payoutAccountNumber,
    'payout_account_name': payoutAccountName,
    'banner_url': bannerUrl,
    'business_name': businessName,
    'business_address': businessAddress,
    'business_reg_number': businessRegNumber,
    'default_pickup_address': defaultPickupAddress,
  };
}

// ============================================
// AuthProvider — Manages authentication state
// extends ChangeNotifier = can notify listeners when data changes
// ============================================
class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  
  // State variables
  User? _user;               // Current logged-in user (null = not logged in)
  bool _isLoading = false;    // Is an auth operation in progress?
  String? _error;             // Error message to display
  bool _isAuthenticated = false;
  
  // Getters — public read-only access to private state
  // In Dart, _ prefix means private, so we need getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  
  // ============================================
  // Check if user is already logged in (on app start)
  // Reads stored token and user data from local storage
  // ============================================
  Future<bool> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);
      
      if (token != null && userData != null) {
        _user = User.fromJson(jsonDecode(userData));
        _isAuthenticated = true;
        
        // Sync FCM Token
        FCMService.syncToken();
        
        notifyListeners();  // Tell all listeners "auth status changed!"
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // ============================================
  // Register a new user
  // ============================================
  Future<bool> register({
    required String fullName,
    required String phone,
    required String password,
    String? email,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();  // UI shows loading spinner
    
    try {
      final response = await _api.post('/auth/register', {
        'fullName': fullName,
        'phone': phone,
        'password': password,
        'email': email,
        'role': role,
      }, auth: false);  // No auth needed for registration
      
      if (response['success'] == true) {
        // Save tokens and user data locally
        await _saveAuthData(response['data']);
        
        // Sync FCM Token
        FCMService.syncToken();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // ============================================
  // Login
  // ============================================
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.post('/auth/login', {
        'phone': phone,
        'password': password,
      }, auth: false);
      
      if (response['success'] == true) {
        await _saveAuthData(response['data']);
        
        // Sync FCM Token
        FCMService.syncToken();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // ============================================
  // Logout — Clear all stored data
  // ============================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
  
  // ============================================
  // Save auth data to local storage
  // Called after successful login/register
  // ============================================
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save tokens
    final tokens = data['tokens'];
    await prefs.setString(AppConstants.tokenKey, tokens['accessToken']);
    await prefs.setString(AppConstants.refreshTokenKey, tokens['refreshToken']);
    
    // Save user data
    final userData = data['user'];
    await prefs.setString(AppConstants.userDataKey, jsonEncode(userData));
    
    // Update state
    _user = User.fromJson(userData);
    _isAuthenticated = true;
  }
  
  // ============================================
  // Fetch Latest Profile
  // ============================================
  Future<bool> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/users/profile');
      
      if (response['success'] == true && response['data'] != null) {
        // Prepare the save data (needs the existing tokens)
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
        
        await _saveAuthData({
          'user': response['data'],
          'tokens': {
            'accessToken': token,
            'refreshToken': refreshToken,
          }
        });
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to fetch profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to load profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // Update Profile
  // ============================================
  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.put('/users/profile', updateData);
      
      if (response['success'] == true) {
        // Refresh local data
        await fetchProfile();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
