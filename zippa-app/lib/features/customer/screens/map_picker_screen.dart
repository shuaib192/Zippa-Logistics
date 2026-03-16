// ============================================
// 🗺️ MAP PICKER SCREEN (map_picker_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zippa_app/core/theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final String title;
  const MapPickerScreen({super.key, required this.title});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  ll.LatLng _lastPosition = const ll.LatLng(6.5244, 3.3792); // Default to Lagos, Nigeria
  String _currentAddress = 'Searching...';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ============================================
  // Get user's current location on map init
  // ============================================
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _currentAddress = 'Location services disabled'; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _currentAddress = 'Permission denied'; });
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    _lastPosition = ll.LatLng(position.latitude, position.longitude);
    
    // Reverse geocode to get initial address
    _updateAddress(_lastPosition);
    
    _mapController.move(_lastPosition, 15.0);
  }

  // ============================================
  // Get address text from coordinates
  // ============================================
  Future<void> _updateAddress(ll.LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = '${place.name}, ${place.subLocality}, ${place.locality}';
        });
      }
    } catch (e) {
      setState(() { _currentAddress = 'Unknown location'; });
    }
  }

  // ============================================
  // Search address using Nominatim (OSM)
  // ============================================
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1&countrycodes=ng'),
        headers: {'User-Agent': 'ZippaLogisticsApp'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newPos = ll.LatLng(lat, lon);
          
          setState(() {
            _lastPosition = newPos;
            _currentAddress = data[0]['display_name'];
          });
          
          _mapController.move(newPos, 15.0);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location not found in Nigeria.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. The Map (OpenStreetMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lastPosition,
              initialZoom: 15,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  _lastPosition = camera.center;
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _updateAddress(_lastPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zippa.app',
              ),
            ],
          ),
          
          // 1.5. Search Bar
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search, color: ZippaColors.primary),
                  suffixIcon: _isSearching 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.clear), 
                        onPressed: () => _searchController.clear(),
                      ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: _searchAddress,
              ),
            ),
          ),
          
          // 2. Fixed Pin in center
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35), // Offset for pin point
              child: Icon(Icons.location_on_rounded, color: ZippaColors.primary, size: 45),
            ),
          ),
          
          // 3. Current Address Display
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: ZippaColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'address': _currentAddress,
                          'lat': _lastPosition.latitude,
                          'lng': _lastPosition.longitude,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ZippaColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 4. Back button & My Location
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.my_location, color: ZippaColors.textPrimary),
            ),
          ),

          // 5. DEBUG BUTTON (V18)
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/push-debug'),
              backgroundColor: Colors.orange,
              mini: true,
              child: const Icon(Icons.bug_report, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
