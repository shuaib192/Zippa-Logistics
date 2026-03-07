import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
                boxShadow: [
                  BoxShadow(color: ZippaColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                   SizedBox(height: 8),
                   Text('₦45,200.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                   SizedBox(height: 24),
                   Row(
                    children: [
                      _SmallStat(label: 'Today', value: '₦3,400'),
                      SizedBox(width: 24),
                      _SmallStat(label: 'Entries', value: '128'),
                      SizedBox(width: 24),
                      _SmallStat(label: 'Bonus', value: '₦500'),
                    ],
                   ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Earnings History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                Text('View Reports', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            _HistoryItem(date: 'Today, 10:45 AM', amount: '₦1,200', desc: 'Delivery #8821'),
            _HistoryItem(date: 'Today, 08:30 AM', amount: '₦2,200', desc: 'Delivery #8819'),
            _HistoryItem(date: 'Yesterday', amount: '₦4,500', desc: 'Daily Total (4 orders)'),
            _HistoryItem(date: '06 Mar 2026', amount: '₦5,100', desc: 'Daily Total (5 orders)'),
          ],
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String date;
  final String amount;
  final String desc;
  const _HistoryItem({required this.date, required this.amount, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZippaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 11)),
            ],
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: ZippaColors.success, fontSize: 16)),
        ],
      ),
    );
  }
}
