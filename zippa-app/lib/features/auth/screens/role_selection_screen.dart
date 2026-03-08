// ============================================
// ROLE SELECTION SCREEN — Professional, no emojis
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Logo
              Image.asset('assets/images/logo.png', height: 44, width: 44)
                  .animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 28),

              Text(
                'Welcome to Zippa',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: ZippaColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),

              const SizedBox(height: 8),

              Text(
                'Select how you want to use the platform',
                style: TextStyle(fontSize: 15, color: ZippaColors.textSecondary),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              Expanded(
                child: Column(
                  children: [
                    _RoleCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Customer',
                      subtitle: 'Send packages and track deliveries',
                      color: ZippaColors.primary,
                      delay: 300,
                      onTap: () => Navigator.pushNamed(context, '/register', arguments: 'customer'),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      icon: Icons.delivery_dining_rounded,
                      title: 'Rider',
                      subtitle: 'Deliver packages and earn money',
                      color: ZippaColors.primaryDark,
                      delay: 420,
                      onTap: () => Navigator.pushNamed(context, '/register', arguments: 'rider'),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      icon: Icons.store_outlined,
                      title: 'Vendor',
                      subtitle: 'Manage business deliveries at scale',
                      color: ZippaColors.accent,
                      delay: 540,
                      onTap: () => Navigator.pushNamed(context, '/register', arguments: 'vendor'),
                    ),
                  ],
                ),
              ),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: ZippaColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: ZippaColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: delay));
  }
}
