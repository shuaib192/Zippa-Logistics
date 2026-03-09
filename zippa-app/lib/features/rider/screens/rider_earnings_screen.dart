import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/features/customer/providers/wallet_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, child) {
        final summary = wallet.summary ?? {};
        final transactions = wallet.transactions;

        return Scaffold(
          drawer: AppDrawer(),
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
            actions: [
              IconButton(
                onPressed: () => wallet.fetchBalance(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await wallet.fetchBalance();
              await wallet.fetchTransactions();
            },
            child: SingleChildScrollView(
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
                        BoxShadow(color: ZippaColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wallet Balance (Settled)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(CurrencyFormatter.formatWithComma(wallet.balance), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _SmallStat(
                              label: 'Today', 
                              value: CurrencyFormatter.formatWithComma(double.tryParse(summary['today_earnings']?.toString() ?? '0') ?? 0)
                            ),
                            const SizedBox(width: 24),
                            _SmallStat(
                              label: 'Deliveries', 
                              value: (summary['today_deliveries'] ?? 0).toString()
                            ),
                            const SizedBox(width: 24),
                            _SmallStat(
                              label: 'Rating', 
                              value: (summary['today_ratings'] ?? 5.0).toString()
                            ),
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
                  if (wallet.isLoading && transactions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
                  else if (transactions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('No earning history yet', style: TextStyle(color: ZippaColors.textSecondary))))
                  else
                    Column(
                      children: transactions.map((tx) {
                        final date = DateTime.parse(tx['created_at']);
                        final isCredit = tx['type'] == 'credit';
                        return _HistoryItem(
                          date: DateFormat('MMM dd, hh:mm a').format(date.toLocal()), 
                          amount: '${isCredit ? '+' : '-'}${CurrencyFormatter.formatWithComma(double.tryParse(tx['amount'].toString()) ?? 0)}', 
                          desc: tx['description'] ?? 'Wallet Transaction',
                          isPositive: isCredit,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
  final bool isPositive;
  const _HistoryItem({required this.date, required this.amount, required this.desc, this.isPositive = true});

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
              Text(date, style: TextStyle(color: ZippaColors.textSecondary, fontSize: 11)),
            ],
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? ZippaColors.success : Colors.red, fontSize: 16)),
        ],
      ),
    );
  }
}
