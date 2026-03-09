import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/marketplace_provider.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/features/customer/screens/map_picker_screen.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/data/models/order_model.dart';
import 'package:zippa_app/features/customer/screens/order_success_screen.dart';

class MarketplaceCartScreen extends StatefulWidget {
  final Map<String, dynamic> vendor;

  const MarketplaceCartScreen({super.key, required this.vendor});

  @override
  State<MarketplaceCartScreen> createState() => _MarketplaceCartScreenState();
}

class _MarketplaceCartScreenState extends State<MarketplaceCartScreen> {
  bool _isEstimating = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize pickup with vendor location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final marketplace = Provider.of<MarketplaceProvider>(context, listen: false);
      if (marketplace.customerNotes != null) {
        _notesController.text = marketplace.customerNotes!;
      }
      
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.setPickup(
        widget.vendor['business_address'] ?? 'Shop Location',
        double.parse(widget.vendor['latitude'].toString()),
        double.parse(widget.vendor['longitude'].toString()),
      );
    });
  }

  Future<void> _pickDropoff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(title: 'Select Dropoff Location'),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.setDropoff(
        result['address'],
        result['lat'],
        result['lng'],
      );
      
      setState(() => _isEstimating = true);
      await orderProvider.estimateFare();
      setState(() => _isEstimating = false);
    }
  }

  Future<void> _placeOrder() async {
    final marketplace = Provider.of<MarketplaceProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (orderProvider.dropoffAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    // Prepare order data with item_price
    final success = await orderProvider.apiClient.post('/orders', {
      'pickup_address': orderProvider.pickupAddress,
      'pickup_lat': orderProvider.pickupLat,
      'pickup_lng': orderProvider.pickupLng,
      'dropoff_address': orderProvider.dropoffAddress,
      'dropoff_lat': orderProvider.dropoffLat,
      'dropoff_lng': orderProvider.dropoffLng,
      'package_size': 'small',
      'package_type': 'marketplace_order',
      'package_description': 'Order from ${widget.vendor['business_name']}',
      'item_price': marketplace.cartTotal,
      'recipient_name': 'Me', // Customer is ordering for themselves
      'recipient_phone': 'N/A',
      'payment_method': 'wallet',
      'customer_notes': _notesController.text,
    });

    if (success['success'] != false) {
      marketplace.clearCart();
      final newOrder = OrderModel.fromJson(success['order']);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessScreen(
            order: newOrder,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success['message'] ?? 'Failed to place order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = Provider.of<MarketplaceProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final estimate = orderProvider.lastEstimate;

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ZippaColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.store_rounded, color: ZippaColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.vendor['business_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(widget.vendor['category_name'], style: TextStyle(color: ZippaColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Items
            const Text('Your Items', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...marketplace.cart.entries.map((entry) {
              final product = marketplace.cartProductDetails[entry.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${entry.value}x ${product?.name ?? "Item"}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(CurrencyFormatter.format((product?.price ?? 0) * entry.value), style: TextStyle(color: ZippaColors.textSecondary, fontSize: 13)),
                  ],
                ),
              );
            }),
            const Divider(height: 32),

            // Delivery Address
            const Text('Delivery Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDropoff,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: orderProvider.dropoffAddress.isEmpty ? ZippaColors.primary : Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: ZippaColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        orderProvider.dropoffAddress.isEmpty ? 'Tap to select delivery address' : orderProvider.dropoffAddress,
                        style: TextStyle(
                          color: orderProvider.dropoffAddress.isEmpty ? ZippaColors.primary : ZippaColors.textPrimary,
                          fontWeight: orderProvider.dropoffAddress.isEmpty ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: ZippaColors.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Order Notes
            const Text('Delivery Instructions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                onChanged: (val) => marketplace.updateNotes(val),
                decoration: InputDecoration(
                  hintText: 'e.g. Please get the freshest milk, or call me if out of stock...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Payment Summary
            const Text('Payment Summary', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Items Subtotal', value: marketplace.cartTotal),
            if (_isEstimating)
              const LinearProgressIndicator()
            else
              _SummaryRow(label: 'Delivery Fee', value: double.parse((estimate?['total_fare'] ?? 0).toString())),
            const Divider(height: 32),
            _SummaryRow(
              label: 'Total Amount', 
              value: marketplace.cartTotal + double.parse((estimate?['total_fare'] ?? 0).toString()),
              isTotal: true,
            ),
            const SizedBox(height: 40),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZippaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: orderProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm & Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Funds will be held in escrow until you confirm delivery.',
                style: TextStyle(fontSize: 11, color: ZippaColors.textLight),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 16 : 14, 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? ZippaColors.textPrimary : ZippaColors.textSecondary,
          )),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14, 
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? ZippaColors.primary : ZippaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
