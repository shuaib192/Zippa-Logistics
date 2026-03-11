import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/features/customer/providers/wallet_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final wallet = Provider.of<WalletProvider>(context, listen: false);
        wallet.fetchBalance();
        wallet.fetchTransactions();
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, child) {
        final summary = wallet.summary ?? {};
        final transactions = wallet.transactions;

        return Scaffold(
          backgroundColor: ZippaColors.background,
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
              await Future.wait([wallet.fetchBalance(), wallet.fetchTransactions()]);
            },
            child: wallet.error != null && transactions.isEmpty
                ? _buildErrorState(wallet.error!)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Earnings Card
                        _buildEarningsCard(context, wallet, summary),
                        const SizedBox(height: 32),
                        
                        // History Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Earnings History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                            if (transactions.isNotEmpty)
                              const Text('View Reports', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (wallet.isLoading && transactions.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
                        else if (transactions.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              try {
                                final tx = transactions[index];
                                final dateStr = tx['created_at']?.toString();
                                final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
                                final isCredit = tx['type'] == 'credit';
                                return _HistoryItem(
                                  date: DateFormat('MMM dd, hh:mm a').format(date.toLocal()),
                                  amount: '${isCredit ? '+' : '-'}${CurrencyFormatter.formatWithComma(double.tryParse(tx['amount']?.toString() ?? '0') ?? 0)}',
                                  desc: tx['description'] ?? 'Wallet Transaction',
                                  isPositive: isCredit,
                                );
                              } catch (e) {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEarningsCard(BuildContext context, WalletProvider wallet, Map<String, dynamic> summary) {
    return Container(
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
          const Text('Available for Payout', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(CurrencyFormatter.formatWithComma(wallet.balance), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                const Text('Upcoming Earnings: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(CurrencyFormatter.formatWithComma(wallet.pendingBalance), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _SmallStat(
                label: 'Today',
                value: CurrencyFormatter.formatWithComma(double.tryParse(summary['today_earnings']?.toString() ?? '0') ?? 0),
              ),
              const SizedBox(width: 24),
              _SmallStat(
                label: 'Deliveries',
                value: (summary['today_deliveries'] ?? 0).toString(),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: wallet.balance < 1000 ? null : () => _showWithdrawDialog(context, wallet),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ZippaColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  fixedSize: const Size(80, 36),
                  elevation: 0,
                ),
                child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: ZippaColors.textLight),
            SizedBox(height: 16),
            Text('No earning history yet', style: TextStyle(color: ZippaColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: ZippaColors.error),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: ZippaColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final wallet = Provider.of<WalletProvider>(context, listen: false);
                wallet.fetchBalance();
                wallet.fetchTransactions();
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(120, 45)),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WalletProvider wallet) {
    double amount = wallet.balance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your funds will be sent to your registered bank account immediately.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ZippaColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount:', style: TextStyle(color: ZippaColors.textSecondary)),
                  Text(CurrencyFormatter.formatWithComma(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            if (wallet.error != null) ...[
              const SizedBox(height: 12),
              Text(wallet.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: wallet.isLoading ? null : () async {
              final success = await wallet.withdraw(amount);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Withdrawal successful! Your funds are on the way.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ZippaColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(100, 40),
            ),
            child: wallet.isLoading
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm'),
          ),
        ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? ZippaColors.success : Colors.red, fontSize: 16)),
        ],
      ),
    );
  }
}
