import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/core/utils/currency_formatter.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';
import 'package:zippa_app/features/rider/screens/rider_order_details_screen.dart';

class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders();
      }
    });
  }

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
        title: const Text('My Deliveries', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final riderOrders = provider.orders.where((o) => o.status != 'pending').toList();
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (riderOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No deliveries yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: riderOrders.length,
            itemBuilder: (context, index) {
              final order = riderOrders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RiderOrderDetailsScreen(orderId: order.id!)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Expanded(child: Text('Order #${order.orderNumber ?? (order.id?.substring(0, 8) ?? '...')}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (order.isMarketplace)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: ZippaColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('MARKETPLACE', style: TextStyle(color: ZippaColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Earnings: ${CurrencyFormatter.formatWithComma(order.riderEarnings)}'),
                      if (order.isMarketplace) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 12, color: ZippaColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(order.vendorName ?? 'Marketplace Store', style: const TextStyle(fontSize: 11, color: ZippaColors.textSecondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted': return ZippaColors.info;
      case 'picked_up': return ZippaColors.primary;
      case 'delivered': return ZippaColors.success;
      default: return Colors.grey;
    }
  }
}
