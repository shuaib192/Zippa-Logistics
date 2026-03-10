// ============================================
// 📍 LOCATION PROVIDER (location_provider.dart)
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zippa_app/data/api/api_client.dart';

class LocationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  // ============================================
  // Start tracking location (For Riders Only)
  // ============================================
  Future<void> startRiderTracking() async {
    if (_isTracking) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _isTracking = true;
    notifyListeners();

    // Listen to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters to save battery/bandwidth
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _sendLocationToBackend(position);
      notifyListeners();
    });
  }

  // ============================================
  // Stop tracking location
  // ============================================
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
  }

  // ============================================
  // Private: Sync with Backend
  // ============================================
  Future<void> _sendLocationToBackend(Position pos) async {
    try {
      await _apiClient.put('/users/location', {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
    } catch (e) {
      debugPrint('Error sending location to backend: $e');
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
