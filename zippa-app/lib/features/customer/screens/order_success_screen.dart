// ============================================
// 🎉 ORDER SUCCESS SCREEN (order_success_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/data/models/order_model.dart';
import 'package:zippa_app/features/customer/screens/order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // 1. Success Icon with Animation
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: ZippaColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: ZippaColors.primary,
                  size: 100,
                ),
              ).animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .shimmer(delay: 800.ms, duration: 1500.ms),
              
              const SizedBox(height: 40),
              
              // 2. Success Text
              const Text(
                'Order Placed!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 16),
              
              Text(
                'Your order #${order.orderNumber} is being processed. We are connecting you with the nearest rider.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: ZippaColors.textSecondary, height: 1.5),
              ).animate().fadeIn(delay: 500.ms),
              
              const Spacer(),
              
                // 3. Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingScreen(orderId: order.id ?? ''),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZippaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5, end: 0),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.5, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
