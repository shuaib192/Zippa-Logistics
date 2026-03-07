import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: ZippaColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                   SizedBox(height: 8),
                   Text('N0.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                   SizedBox(height: 24),
                   Row(
                    children: [
                      Text('Today: N0.00', style: TextStyle(color: Colors.white, fontSize: 14)),
                      SizedBox(width: 16),
                      Text('Commission: N0.00', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                   ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Earnings History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Reports', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('No earnings yet', style: TextStyle(color: ZippaColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
