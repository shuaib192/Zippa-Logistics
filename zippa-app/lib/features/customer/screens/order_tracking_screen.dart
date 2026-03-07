// ============================================
// ORDER TRACKING SCREEN (order_tracking_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
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
  final MapController _mapController = MapController();
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
      });
    }
  }

  void _fitBounds() {
    if (_order == null) return;
    
    // Calculate bounds manually if needed or use center/zoom
    _mapController.move(
      LatLng(_order!.pickupLat, _order!.pickupLng),
      13.0,
    );
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
              // 1. MAP VIEW (OpenStreetMap)
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_order!.pickupLat, _order!.pickupLng),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.zippa.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_order!.pickupLat, _order!.pickupLng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: ZippaColors.primary, size: 40),
                        ),
                        Marker(
                          point: LatLng(_order!.dropoffLat, _order!.dropoffLng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: ZippaColors.accent, size: 40),
                        ),
                      ],
                    ),
                  ],
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
                        color: Colors.black.withValues(alpha: 0.1),
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
            color: statusColor.withValues(alpha: 0.1),
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
        color: ZippaColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ZippaColors.primary.withValues(alpha: 0.1),
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
