import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/notification_provider.dart';
import 'package:intl/intl.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: ZippaColors.primary.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(color: ZippaColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                final isRead = notification['is_read'] == true;
                final date = DateTime.parse(notification['created_at']);
                
                return InkWell(
                  onTap: () {
                    if (!isRead) {
                      provider.markAsRead(notification['id']);
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getIconColor(notification['type']).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(notification['type']),
                          color: _getIconColor(notification['type']),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notification['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 15,
                                    color: isRead ? ZippaColors.textSecondary : ZippaColors.textPrimary,
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: ZippaColors.primary, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification['message'] ?? '',
                              style: TextStyle(
                                color: isRead ? ZippaColors.textSecondary.withValues(alpha: 0.7) : ZippaColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM dd, hh:mm a').format(date.toLocal()),
                              style: TextStyle(color: ZippaColors.textSecondary.withValues(alpha: 0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'order': return Icons.local_shipping_outlined;
      case 'wallet': return Icons.account_balance_wallet_outlined;
      case 'system': return Icons.info_outline;
      default: return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'order': return ZippaColors.primary;
      case 'wallet': return Colors.green;
      case 'system': return Colors.blue;
      default: return ZippaColors.primary;
    }
  }
}
