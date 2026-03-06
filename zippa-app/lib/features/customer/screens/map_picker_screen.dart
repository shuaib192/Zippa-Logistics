// ============================================
// 🗺️ MAP PICKER SCREEN (map_picker_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final String title;
  const MapPickerScreen({super.key, required this.title});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _lastPosition = const LatLng(6.5244, 3.3792); // Default to Lagos, Nigeria
  String _currentAddress = 'Searching...';
  bool _isLoading = true;

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
      setState(() { _currentAddress = 'Location services disabled'; _isLoading = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _currentAddress = 'Permission denied'; _isLoading = false; });
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    _lastPosition = LatLng(position.latitude, position.longitude);
    
    // Reverse geocode to get initial address
    _updateAddress(_lastPosition);
    
    setState(() { _isLoading = false; });
    
    _mapController?.animateCamera(CameraUpdate.newLatLng(_lastPosition));
  }

  // ============================================
  // Get address text from coordinates
  // ============================================
  Future<void> _updateAddress(LatLng pos) async {
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
          // 1. The Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _lastPosition, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (pos) => _lastPosition = pos.target,
            onCameraIdle: () => _updateAddress(_lastPosition),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
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
        ],
      ),
    );
  }
}
