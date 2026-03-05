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

// User model — represents a logged-in user
class User {
  final String id;
  final String? email;
  final String phone;
  final String fullName;
  final String role;
  final String kycStatus;
  
  User({
    required this.id,
    this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.kycStatus,
  });
  
  // Factory constructor — creates a User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'customer',
      kycStatus: json['kycStatus'] ?? 'unverified',
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
  
  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
