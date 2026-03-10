// ============================================
// 📦 RIDER ORDER DETAILS SCREEN (rider_order_details_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/data/models/order_model.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:zippa_app/features/chat/screens/chat_screen.dart';

class RiderOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const RiderOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<RiderOrderDetailsScreen> createState() => _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState extends State<RiderOrderDetailsScreen> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final order = await provider.fetchOrderDetails(widget.orderId);
    if (mounted) {
      if (order != null) {
        provider.fetchRoute(order.pickupLat, order.pickupLng, order.dropoffLat, order.dropoffLng);
      }
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    setState(() => _isLoading = true);
    
    final success = await provider.updateOrderStatus(widget.orderId, status);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _loadDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $status')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to update status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: Text('Order #${_order!.orderNumber ?? widget.orderId.substring(0, 8)}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    orderId: widget.orderId,
                    recipientName: _order!.recipientName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
      ),
      body: Column(
        children: [
          // In-App Tracking Map
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_order!.pickupLat, _order!.pickupLng),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.zippa.app',
                ),
                Consumer<OrderProvider>(
                  builder: (context, provider, child) => PolylineLayer(
                    polylines: [
                      Polyline(
                        points: provider.currentRoute,
                        color: ZippaColors.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
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
                      child: const Icon(Icons.location_on, color: ZippaColors.error, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
            // Status Badge
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Pickup & Dropoff
            _buildAddressCard(),
            const SizedBox(height: 24),

            // Marketplace Details (Items & Notes)
            if (_order!.isMarketplace) _buildMarketplaceCard(),
            
            // Standard Package Details
            if (!_order!.isMarketplace) _buildPackageCard(),
            
            const SizedBox(height: 24),

            // Earnings Card
            _buildEarningsCard(),
            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildStatusCard() {
    String statusStr = _order!.status.toUpperCase();
    Color color = ZippaColors.primary;
    if (statusStr == 'PENDING') color = ZippaColors.warning;
    if (statusStr == 'DELIVERED') color = ZippaColors.success;
    if (statusStr == 'CANCELLED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.delivery_dining, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Status', style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
                Text(statusStr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationRow(
            icon: Icons.circle, 
            iconColor: ZippaColors.primary, 
            label: _order!.isMarketplace ? 'VENDOR: ${_order!.vendorName ?? "Marketplace Store"}' : 'PICKUP',
            address: _order!.pickupAddress,
            showNavigate: true,
            lat: _order!.pickupLat,
            lng: _order!.pickupLng,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(width: 2, height: 30, color: Colors.grey.shade100),
          ),
          _buildLocationRow(
            icon: Icons.location_on, 
            iconColor: ZippaColors.error, 
            label: 'DROPOFF: ${_order!.recipientName}',
            address: _order!.dropoffAddress,
            showNavigate: _order!.status == 'picked_up',
            lat: _order!.dropoffLat,
            lng: _order!.dropoffLng,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon, 
    required Color iconColor, 
    required String label, 
    required String address,
    bool showNavigate = false,
    double? lat,
    double? lng,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ZippaColors.textSecondary)),
              const SizedBox(height: 4),
              Text(address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (showNavigate && lat != null && lng != null)
          IconButton(
            icon: const Icon(Icons.directions_outlined, color: ZippaColors.primary),
            onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng')),
          ),
      ],
    );
  }

  Widget _buildMarketplaceCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ZippaColors.secondary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: ZippaColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Marketplace Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 24),
          Text(_order!.packageDescription ?? 'Items from ${_order!.vendorName}', style: const TextStyle(fontSize: 14)),
          if (_order!.customerNotes != null && _order!.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOMER NOTES:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 4),
                  Text(_order!.customerNotes!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Package Type', style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
          Text(_order!.packageType.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Description', style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
          Text(_order!.packageDescription ?? 'No description provided', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ZippaColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Your Earnings', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text(CurrencyFormatter.formatWithComma(_order!.riderEarnings), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_order!.status == 'pending') {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _updateStatus('accepted'),
          style: ElevatedButton.styleFrom(backgroundColor: ZippaColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }

    if (_order!.status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _updateStatus('picked_up'),
          style: ElevatedButton.styleFrom(backgroundColor: ZippaColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text(_order!.isMarketplace ? 'Items Picked Up from Store' : 'Package Picked Up', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }

    if (_order!.status == 'picked_up') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _updateStatus('delivered'),
              style: ElevatedButton.styleFrom(backgroundColor: ZippaColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:${_order!.recipientPhone}')),
            icon: const Icon(Icons.phone),
            label: Text('Call Recipient (${_order!.recipientName})'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
