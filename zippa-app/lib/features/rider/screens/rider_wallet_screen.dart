import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/features/customer/providers/wallet_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart' as zippa_auth;
import 'package:zippa_app/core/providers/navigation_provider.dart';

class RiderWalletScreen extends StatefulWidget {
  final bool showWithdrawDialog;
  const RiderWalletScreen({super.key, this.showWithdrawDialog = false});

  @override
  State<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final wallet = Provider.of<WalletProvider>(context, listen: false);
        wallet.fetchBalance();
        wallet.fetchTransactions();
        if (widget.showWithdrawDialog) {
          _showWithdrawDialog(context, wallet);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: const Text('Zippa Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final summary = wallet.summary ?? {};
          final todayEarnings = double.tryParse(summary['today_earnings']?.toString() ?? '0') ?? 0;
          final totalEarnings = double.tryParse(summary['total_earnings']?.toString() ?? '0') ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              await wallet.fetchBalance();
              await wallet.fetchTransactions();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Premium Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: ZippaColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: ZippaColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Available for Withdrawal', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatWithComma(wallet.balance), 
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _HeroActionBtn(
                                icon: Icons.arrow_upward_rounded, 
                                label: 'Withdraw',
                                onTap: () => _showWithdrawDialog(context, wallet),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Earnings Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: "Today's Pay",
                          value: CurrencyFormatter.formatWithComma(todayEarnings),
                          icon: Icons.today_rounded,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: "Total Earned",
                          value: CurrencyFormatter.formatWithComma(totalEarnings),
                          icon: Icons.account_balance_wallet_rounded,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {}, 
                        child: const Text('See All', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                  
                  if (wallet.isLoading && wallet.transactions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))
                  else if (wallet.transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No transactions yet', style: TextStyle(color: ZippaColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: wallet.transactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final tx = wallet.transactions[index];
                        final isCredit = tx['type'] == 'credit';
                        final date = DateTime.parse(tx['created_at']);
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCredit ? Icons.add_rounded : Icons.remove_rounded,
                              color: isCredit ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(tx['description'] ?? 'Wallet Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date.toLocal()), style: const TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
                          trailing: Text(
                            '${isCredit ? '+' : '-'}${CurrencyFormatter.formatWithComma(double.parse(tx['amount'].toString()))}',
                            style: TextStyle(
                              color: isCredit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WalletProvider wallet) {
    final authProvider = Provider.of<zippa_auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final controller = TextEditingController(text: wallet.balance > 0 ? wallet.balance.toStringAsFixed(0) : "");
    
    // Check if payout details are set
    if (user?.payoutAccountNumber == null || user!.payoutAccountNumber!.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bank Details Missing'),
          content: const Text('You need to provide your bank account details in your profile before you can withdraw earnings.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<NavigationProvider>(context, listen: false).setIndex(4);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ZippaColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Setup Bank Profile'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Withdraw Funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      'Balance: ${CurrencyFormatter.formatWithComma(wallet.balance)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Transfer your earnings to your bank account.', style: TextStyle(color: ZippaColors.textSecondary, fontSize: 13)),
              
              const SizedBox(height: 24),
              const Text('Recipient Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZippaColors.primary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ZippaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ZippaColors.primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: ZippaColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_rounded, color: ZippaColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.payoutAccountName ?? 'Account Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${user.payoutBankName} • ${user.payoutAccountNumber}', style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount to Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZippaColors.primary)),
                  GestureDetector(
                    onTap: () => controller.text = wallet.balance.toStringAsFixed(0),
                    child: const Text('Withdraw All', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₦ ',
                  prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                  filled: true,
                  fillColor: ZippaColors.surface.withAlpha(50),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Minimum withdrawal: ₦1,000', style: TextStyle(color: Colors.grey, fontSize: 11)),

              if (wallet.error != null) ...[
                const SizedBox(height: 16),
                Text(wallet.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: wallet.isLoading ? null : () async {
                    final amount = double.tryParse(controller.text);
                    if (amount == null || amount < 1000) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is ₦1,000')));
                       return;
                    }
                    if (amount > wallet.balance) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
                       return;
                    }

                    final success = await wallet.withdraw(amount);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Success'),
                          content: const Text('Your withdrawal request has been submitted. Funds will reach your account shortly.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Great!')),
                          ],
                        ),
                      );
                    }
                    if (!success && context.mounted) {
                      setModalState(() {}); // Refresh to show error
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZippaColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: wallet.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Withdrawal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeroActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
