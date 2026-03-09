import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
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
                            onTap: () => _showFundDialog(context, wallet),
                          ),
                          const SizedBox(width: 16),
                          _ActionBtn(
                            icon: Icons.refresh_rounded, 
                            label: 'Refresh',
                            onTap: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              await wallet.refreshBalance();
                              if (wallet.error != null) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text(wallet.error!)),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Balance refresh requested!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (wallet.virtualAccount != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ZippaColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ZippaColors.primary.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 16, color: ZippaColors.primary),
                            SizedBox(width: 8),
                            Text('Dedicated Funding Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZippaColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Transfer money to this unique account to fund your wallet instantly.', style: TextStyle(fontSize: 11, color: ZippaColors.textSecondary)),
                        const SizedBox(height: 16),
                        _AccountDetailRow(label: 'Bank Name', value: wallet.virtualAccount!['bank_name'] ?? 'Wema Bank'),
                        _AccountDetailRow(
                          label: 'Account Number', 
                          value: wallet.virtualAccount!['account_number'] ?? '---', 
                          isCopyable: true,
                        ),
                        _AccountDetailRow(label: 'Account Name', value: wallet.virtualAccount!['account_name'] ?? 'Zippa Logistics'),
                      ],
                    ),
                  ),
                ] else if (wallet.virtualAccountMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(wallet.virtualAccountMessage!, style: TextStyle(fontSize: 12, color: Colors.blue.shade800))),
                      ],
                    ),
                  ),
                ],
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

  void _showFundDialog(BuildContext context, WalletProvider wallet) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Fund Your Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose your preferred payment method below.', style: TextStyle(color: ZippaColors.textSecondary, fontSize: 13)),
            
            const SizedBox(height: 32),
            const Text('Option 1: Bank Transfer (Fastest)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZippaColors.primary)),
            const SizedBox(height: 12),
            
            if (wallet.virtualAccount != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ZippaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ZippaColors.primary.withAlpha(30)),
                ),
                child: Column(
                  children: [
                    _AccountDetailRow(label: 'Bank Name', value: wallet.virtualAccount!['bank_name'] ?? 'Wema Bank'),
                    _AccountDetailRow(
                      label: 'Account Number', 
                      value: wallet.virtualAccount!['account_number'] ?? '---', 
                      isCopyable: true,
                    ),
                    _AccountDetailRow(label: 'Account Name', value: wallet.virtualAccount!['account_name'] ?? 'Zippa Logistics'),
                    const SizedBox(height: 4),
                    const Text('Transfer any amount to this account. Your balance will update automatically.', 
                      style: TextStyle(fontSize: 10, color: ZippaColors.textSecondary, fontStyle: FontStyle.italic)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  wallet.virtualAccountMessage ?? 'Setting up your unique dedicated funding account... Please check back in a moment.',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),

            const SizedBox(height: 32),
            const Text('Option 2: Instant Card Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZippaColors.primary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount to fund (N)',
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: ZippaColors.primary),
                filled: true,
                fillColor: ZippaColors.surface.withAlpha(50),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text);
                  if (amount != null && amount > 0) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZippaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Fund Instantly', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;

  const _AccountDetailRow({
    required this.label,
    required this.value,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 13)),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ZippaColors.textPrimary),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label copied to clipboard')),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 16, color: ZippaColors.primary),
                ),
              ],
            ],
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
