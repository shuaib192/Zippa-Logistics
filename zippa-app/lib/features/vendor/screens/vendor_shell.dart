import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/providers/navigation_provider.dart';
import 'package:zippa_app/features/vendor/screens/vendor_home_screen.dart';
import 'package:zippa_app/features/customer/screens/customer_wallet_screen.dart';
import 'package:zippa_app/core/widgets/app_drawer.dart';

import 'package:zippa_app/features/vendor/screens/vendor_orders_screen.dart';
import 'package:zippa_app/features/vendor/screens/vendor_products_screen.dart';
import 'package:zippa_app/features/vendor/screens/vendor_profile_screen.dart';
import 'package:zippa_app/core/services/fcm_service.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () async {
          if (mounted) {
            await FCMService.syncToken();
            await FCMService.subscribeToTopic('vendors');
          }
        });
      }
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return 'Vendor Dashboard';
      case 1: return 'Store Orders';
      case 2: return 'Product Manager';
      case 3: return 'Earnings & Wallet';
      case 4: return 'Profile';
      default: return 'Zippa Vendor';
    }
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0: return const VendorHomeScreen();
      case 1: return const VendorOrdersScreen();
      case 2: return const VendorProductsScreen();
      case 3: return const CustomerWalletScreen(); // Reused for vendors
      case 4: return const VendorProfileScreen(); // Dedicated for vendors
      default: return const VendorHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final currentIndex = navProvider.currentIndex;

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_getAppBarTitle(currentIndex), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: _getScreen(currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => navProvider.setIndex(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ZippaColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
