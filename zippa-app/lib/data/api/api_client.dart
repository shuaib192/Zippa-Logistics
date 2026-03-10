// ============================================
// 🎓 API CLIENT (api_client.dart)
//
// WHAT IS AN API CLIENT?
// It's a helper class that makes HTTP requests to our backend.
// Instead of writing URL and headers every time, we write them
// once here and call simple methods like:
//   apiClient.post('/auth/register', data)
//
// It also handles:
// - Adding the JWT token to every request (for auth)
// - Converting responses from JSON to Dart objects
// - Error handling
// ============================================

import 'dart:convert';  // For JSON encoding/decoding
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zippa_app/core/constants/app_constants.dart';

class ApiClient {
  final String baseUrl = AppConstants.apiBaseUrl;
  
  // ============================================
  // GET the stored JWT token from local storage
  // ============================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
  
  // ============================================
  // Build headers for requests
  // Every request needs Content-Type (what format the data is in)
  // Authenticated requests also need the Bearer token
  // ============================================
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (auth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // ============================================
  // GET request — Retrieve data from the server
  // Example: get('/users/profile') → your profile data
  // ============================================
  Future<Map<String, dynamic>> get(String endpoint, {bool auth = true}) async {
    try {
      final headers = await _getHeaders(auth: auth);
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // ============================================
  // POST request — Send new data to the server
  // Example: post('/auth/register', {name: 'John', ...})
  // ============================================
  Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> body, 
    {bool auth = true}
  ) async {
    try {
      final headers = await _getHeaders(auth: auth);
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),  // Convert Dart Map to JSON string
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // ============================================
  // PUT request — Update existing data
  // Example: put('/users/profile', {name: 'New Name'})
  // ============================================
  Future<Map<String, dynamic>> put(
    String endpoint, 
    Map<String, dynamic> body, 
    {bool auth = true}
  ) async {
    try {
      final headers = await _getHeaders(auth: auth);
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // ============================================
  // DELETE request — Remove data from the server
  // Example: delete('/api/products/123')
  // ============================================
  Future<Map<String, dynamic>> delete(String endpoint, {bool auth = true}) async {
    try {
      final headers = await _getHeaders(auth: auth);
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // ============================================
  // Handle the server's response
  // Parse JSON and check for errors
  // ============================================
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success! (200-299 are success codes)
      return data;
    } else {
      // Error from server
      return {
        'success': false,
        'message': data['message'] ?? 'Something went wrong',
        'statusCode': response.statusCode,
      };
    }
  }
  
  // ============================================
  // Handle network errors (no internet, server down, etc.)
  // ============================================
  Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'message': 'Connection error. Please check your internet and try again.',
      'error': error.toString(),
    };
  }
}
