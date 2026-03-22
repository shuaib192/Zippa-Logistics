// ============================================
// PAYSTACK WEBVIEW SCREEN (paystack_webview_screen.dart)
// Opens the Paystack payment URL in an in-app WebView
// instead of redirecting to an external browser.
// ============================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

class PaystackWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaystackWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState extends State<PaystackWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // Detect Paystack callback URL (payment completed)
            if (url.contains('callback') ||
                url.contains('paystack.co/close') ||
                url.contains('trxref=') ||
                url.contains('reference=')) {
              // Payment was completed or cancelled — return success
              if (url.contains('trxref=') || url.contains('reference=')) {
                Navigator.pop(context, true); // Success
              } else {
                Navigator.pop(context, false); // Cancelled/closed
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Payment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showCancelDialog(context),
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(ZippaColors.primary),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
            'Are you sure you want to cancel this payment? Your wallet will not be funded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Paying'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
