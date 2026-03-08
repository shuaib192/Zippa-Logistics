// ============================================
// 📊 FARE SUMMARY SCREEN (fare_summary_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/features/customer/screens/order_success_screen.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';

class FareSummaryScreen extends StatelessWidget {
  const FareSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final estimate = provider.lastEstimate;

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Trip Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.location_on_rounded,
                    color: ZippaColors.primary,
                    title: 'Pickup',
                    value: estimate?['pickup_address'] ?? 'Not set',
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Divider(height: 30, thickness: 1),
                  ),
                  _SummaryRow(
                    icon: Icons.flag_rounded,
                    color: ZippaColors.accent,
                    title: 'Drop-off',
                    value: estimate?['dropoff_address'] ?? 'Not set',
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // 2. Package Details
            const Text('Package Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ZippaColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _InfoItem(label: 'Size', value: estimate?['package_size']?.toString().toUpperCase() ?? '-'),
                  _InfoItem(label: 'Type', value: estimate?['package_type']?.toString().toUpperCase() ?? '-'),
                  _InfoItem(label: 'Distance', value: '${(double.tryParse(estimate?['distance']?.toString() ?? '0') ?? 0).toStringAsFixed(1)} km'),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // 3. Price Breakdown
            const Text('Price Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _PriceRow(label: 'Fare Estimate', value: CurrencyFormatter.formatWithComma(estimate?['subtotal'])),
            _PriceRow(label: 'Service Fee', value: CurrencyFormatter.formatWithComma(estimate?['platform_fee'])),
            const Divider(height: 32),
            _PriceRow(label: 'Total Fare', value: CurrencyFormatter.formatWithComma(estimate?['total_fare']), isTotal: true),

            const SizedBox(height: 40),
            
            // Payment Method Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ZippaColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments_outlined, color: ZippaColors.primary),
                  SizedBox(width: 12),
                  Text('Payment Method: Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w600, color: ZippaColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _handleConfirm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ZippaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: provider.isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirm & Request Rider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _handleConfirm(BuildContext context) async {
    final order = await context.read<OrderProvider>().createOrder();
    if (order != null && context.mounted) {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        (route) => route.isFirst,
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<OrderProvider>().error ?? 'Failed to place order')),
      );
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  const _SummaryRow({required this.icon, required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: ZippaColors.textLight, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ZippaColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: ZippaColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _PriceRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 15, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? ZippaColors.textPrimary : ZippaColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: isTotal ? 22 : 16, fontWeight: FontWeight.bold, color: isTotal ? ZippaColors.primary : ZippaColors.textPrimary)),
      ],
    );
  }
}
