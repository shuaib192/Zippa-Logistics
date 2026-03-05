// ============================================
// 🎓 ROLE SELECTION SCREEN (role_selection_screen.dart)
//
// After onboarding, users choose WHO they are:
// - Customer (I want to send packages)
// - Rider (I want to deliver and earn)
// - Vendor (I have a business)
//
// This choice determines which dashboard they see
// and what features are available to them.
//
// The role is saved and sent with registration.
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
              const SizedBox(height: 40),
              
              // Header
              Text(
                'Welcome to\nZippa! 👋',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: ZippaColors.textPrimary,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 12),
              
              Text(
                'How would you like to use Zippa?',
                style: TextStyle(
                  fontSize: 16,
                  color: ZippaColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              
              const SizedBox(height: 40),
              
              // Role cards
              Expanded(
                child: Column(
                  children: [
                    // Customer card
                    _RoleCard(
                      icon: Icons.person_rounded,
                      title: 'Customer',
                      subtitle: 'Send packages & track deliveries',
                      color: ZippaColors.primary,
                      delay: 300,
                      onTap: () {
                        Navigator.pushNamed(context, '/register', arguments: 'customer');
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Rider card
                    _RoleCard(
                      icon: Icons.delivery_dining_rounded,
                      title: 'Rider',
                      subtitle: 'Deliver packages & earn money',
                      color: ZippaColors.primaryLight,
                      delay: 450,
                      onTap: () {
                        Navigator.pushNamed(context, '/register', arguments: 'rider');
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vendor card
                    _RoleCard(
                      icon: Icons.store_rounded,
                      title: 'Vendor',
                      subtitle: 'Manage business deliveries',
                      color: ZippaColors.primaryDark,
                      delay: 600,
                      onTap: () {
                        Navigator.pushNamed(context, '/register', arguments: 'vendor');
                      },
                    ),
                  ],
                ),
              ),
              
              // Already have account? Login
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: ZippaColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: ZippaColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Role Card Widget — A reusable, tappable card
// The _ prefix makes it private to this file
// ============================================
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon in colored circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            
            const SizedBox(width: 20),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ZippaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: ZippaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: delay));
  }
}
