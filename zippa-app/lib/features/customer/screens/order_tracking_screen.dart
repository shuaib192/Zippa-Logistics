// ============================================
// 📍 ORDER TRACKING SCREEN (order_tracking_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/data/models/order_model.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final order = await provider.fetchOrderDetails(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
        if (order != null) {
          _updateMarkers(order);
        }
      });
    }
  }

  void _updateMarkers(OrderModel order) {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(order.pickupLat, order.pickupLng),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(order.dropoffLat, order.dropoffLng),
        infoWindow: const InfoWindow(title: 'Drop-off Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    // Zoom to fit markers
    if (_mapController != null) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_order == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _order!.pickupLat < _order!.dropoffLat ? _order!.pickupLat : _order!.dropoffLat,
        _order!.pickupLng < _order!.dropoffLng ? _order!.pickupLng : _order!.dropoffLng,
      ),
      northeast: LatLng(
        _order!.pickupLat > _order!.dropoffLat ? _order!.pickupLat : _order!.dropoffLat,
        _order!.pickupLng > _order!.dropoffLng ? _order!.pickupLng : _order!.dropoffLng,
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: const Center(child: Text('Order not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order!.orderNumber ?? widget.orderId.substring(0, 8)}'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;

          return Stack(
            children: [
              // 1. MAP VIEW
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_order!.pickupLat, _order!.pickupLng),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitBounds();
                  },
                  markers: _markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),

              // 2. STATUS CARD (Responsive)
              Positioned(
                left: isWide ? 20 : 0,
                right: isWide ? null : 0,
                bottom: isWide ? 20 : 0,
                child: Container(
                  width: isWide ? 400 : constraints.maxWidth,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isWide 
                      ? BorderRadius.circular(24) 
                      : const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(),
                      const Divider(height: 32),
                      _buildTimeline(),
                      const SizedBox(height: 20),
                      _buildRiderInfo(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader() {
    String statusText = 'Processing...';
    Color statusColor = ZippaColors.warning;

    switch (_order!.status) {
      case 'pending':
        statusText = 'Searching for Rider';
        statusColor = ZippaColors.warning;
        break;
      case 'accepted':
        statusText = 'Rider is arriving';
        statusColor = ZippaColors.info;
        break;
      case 'picked_up':
        statusText = 'Package en route';
        statusColor = ZippaColors.primary;
        break;
      case 'delivered':
        statusText = 'Delivered';
        statusColor = ZippaColors.success;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Spacer(),
        Text(
          'ETA: 15-20 mins',
          style: TextStyle(color: ZippaColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Row(
      children: [
        _buildTimelineItem('Ordered', true),
        _buildTimelineDivider(true),
        _buildTimelineItem('Accepted', ['accepted', 'picked_up', 'delivered'].contains(_order!.status)),
        _buildTimelineDivider(['accepted', 'picked_up', 'delivered'].contains(_order!.status)),
        _buildTimelineItem('Picked Up', ['picked_up', 'delivered'].contains(_order!.status)),
        _buildTimelineDivider(['picked_up', 'delivered'].contains(_order!.status)),
        _buildTimelineItem('Delivered', _order!.status == 'delivered'),
      ],
    );
  }

  Widget _buildTimelineItem(String label, bool isDone) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone ? ZippaColors.success : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check : Icons.circle,
            size: 14,
            color: isDone ? Colors.white : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDone ? ZippaColors.textPrimary : ZippaColors.textLight,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isDone ? ZippaColors.success : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildRiderInfo() {
    if (_order!.riderId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Finding your rider...', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Matching with the nearest delivery partner', style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZippaColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ZippaColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: ZippaColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rider Assigned', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('John Doe • 4.9 ★', style: const TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone_in_talk_rounded, color: ZippaColors.primary),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_rounded, color: ZippaColors.primary),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
