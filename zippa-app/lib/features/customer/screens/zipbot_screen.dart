import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

class ZipBotScreen extends StatelessWidget {
  const ZipBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZipBot AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: ZippaColors.primary),
            const SizedBox(height: 24),
            const Text('ZipBot is coming soon!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'I will be your AI assistant for all your logistics needs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ZippaColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
