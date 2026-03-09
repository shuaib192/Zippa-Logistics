import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/features/customer/providers/wallet_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
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
        return RefreshIndicator(
          onRefresh: () async {
            await wallet.fetchBalance();
            await wallet.fetchTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.formatWithComma(wallet.balance), 
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _ActionBtn(
                            icon: Icons.add, 
                            label: 'Add Money',
                            onTap: () => _showFundDialog(context),
                          ),
                          const SizedBox(width: 16),
                          _ActionBtn(
                            icon: Icons.arrow_outward_rounded, 
                            label: 'Withdraw',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Withdrawal coming soon!'))
                              );
                            },
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
                    Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('See all', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                if (wallet.isLoading && wallet.transactions.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
                else if (wallet.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No transactions yet', style: TextStyle(color: ZippaColors.textSecondary)),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: wallet.transactions.map((tx) {
                      final isCredit = tx['type'] == 'credit';
                      final date = DateTime.parse(tx['created_at']);
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.add_rounded : Icons.remove_rounded,
                            color: isCredit ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(tx['description'] ?? 'Wallet Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date.toLocal()), style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${isCredit ? '+' : '-'}${CurrencyFormatter.formatWithComma(double.parse(tx['amount'].toString()))}',
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFundDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fund Wallet'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter Amount',
            prefixText: 'N',
            hintText: 'e.g. 1000',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                final wallet = Provider.of<WalletProvider>(context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final success = await wallet.fundWallet(amount);
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Successfully funded wallet with N$amount')),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(wallet.error ?? 'Funding failed')),
                  );
                }
              }
            },
            child: const Text('Fund'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
