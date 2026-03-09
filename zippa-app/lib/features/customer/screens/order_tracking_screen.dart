// ============================================
// ORDER TRACKING SCREEN (order_tracking_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
      bool shouldShowRating = _order?.status != 'delivered' && order?.status == 'delivered';
      setState(() {
        _order = order;
        _isLoading = false;
      });
      if (shouldShowRating) {
        _showRatingDialog();
      }
    }
  }

  Future<void> _confirmDelivery() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    setState(() => _isLoading = true);
    
    final success = await provider.confirmDelivery(widget.orderId);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _loadOrderDetails(); // Reload to get updated status
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery confirmed and payments released!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to confirm delivery.')),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    setState(() => _isLoading = true);
    
    final success = await provider.cancelOrder(widget.orderId);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel order.')),
        );
      }
    }
  }

  void _showRatingDialog() {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate your Delivery'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience with the rider?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => rating = index + 1),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                setState(() => isSubmitting = true);
                final provider = Provider.of<OrderProvider>(context, listen: false);
                try {
                  final response = await provider.apiClient.post('/ratings', {
                    'orderId': widget.orderId,
                    'rating': rating,
                    'comment': commentController.text,
                  });
                  if (response['success'] != false) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you for your feedback!')),
                      );
                    }
                  }
                } catch (e) {
                   debugPrint('Rating error: $e');
                } finally {
                  if (context.mounted) setState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ZippaColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting 
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
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
                    initialCenter: ll.LatLng(_order!.pickupLat, _order!.pickupLng),
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
                          point: ll.LatLng(_order!.pickupLat, _order!.pickupLng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: ZippaColors.primary, size: 40),
                        ),
                        Marker(
                          point: ll.LatLng(_order!.dropoffLat, _order!.dropoffLng),
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
                  padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 24),
                      _buildRiderInfo(),
                      
                      // Escrow Confirmation Button
                      if (_order!.status == 'delivered' && !_order!.customerConfirmed) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ZippaColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ZippaColors.primary.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: ZippaColors.primary, size: 20),
                                  SizedBox(width: 8),
                                  Text('Payment Held in Escrow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'The rider has marked this as delivered. Please confirm you have received your package to release payment to the vendor and rider.',
                                style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _confirmDelivery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ZippaColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Confirm & Release Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_order!.customerConfirmed) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ZippaColors.success.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ZippaColors.success.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: ZippaColors.success, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Payment Settled', style: TextStyle(fontWeight: FontWeight.bold, color: ZippaColors.success)),
                                    Text('Funds have been released to the vendor and rider.', style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
      case 'cancelled':
        statusText = 'Cancelled';
        statusColor = Colors.red;
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
        if (_order!.status != 'delivered' && _order!.status != 'cancelled')
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
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
          ),
          if (_order!.status == 'pending') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
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
            backgroundImage: _order!.riderAvatar != null ? NetworkImage(_order!.riderAvatar!) : null,
            child: _order!.riderAvatar == null ? const Icon(Icons.person, color: ZippaColors.primary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rider Assigned', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_order!.riderName ?? 'Rider'} • Assigned', style: const TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
               if (_order!.riderPhone != null) {
                 launchUrl(Uri.parse('tel:${_order!.riderPhone}'));
               }
            },
            icon: const Icon(Icons.phone_in_talk_rounded, color: ZippaColors.primary),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming in Phase 7!')),
              );
            },
            icon: const Icon(Icons.chat_bubble_rounded, color: ZippaColors.primary),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
