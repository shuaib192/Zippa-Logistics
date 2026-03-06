// ============================================
// ONBOARDING SCREEN — Professional, emoji-free
// Uses the actual Zippa logo with role-context
// illustrations instead of emoji icons.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Professional onboarding pages — no emojis, clean business copy
  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.local_shipping_rounded,
      'color': ZippaColors.primary,
      'label': 'SEND',
      'title': 'Send Packages Anywhere',
      'description':
          'Schedule pickups, track deliveries in real time, and get packages to their destination — fast, easy, and safe.',
    },
    {
      'icon': Icons.delivery_dining_rounded,
      'color': ZippaColors.primaryDark,
      'label': 'EARN',
      'title': 'Earn as a Delivery Partner',
      'description':
          'Join thousands of riders earning competitive income. Flexible hours, instant wallet payouts, and performance bonuses.',
    },
    {
      'icon': Icons.store_rounded,
      'color': ZippaColors.accent,
      'label': 'GROW',
      'title': 'Scale Your Business',
      'description':
          'Manage all your business deliveries in one place. Bulk orders, real-time analytics, and priority support for vendors.',
    },
  ];

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/role-select');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ZippaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // — Top bar: Logo + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    width: 36,
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: ZippaColors.textSecondary, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            // — Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final color = page['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration block with logo + icon overlay
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            Container(
                              width: size.width * 0.7,
                              height: size.width * 0.7,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Inner circle
                            Container(
                              width: size.width * 0.55,
                              height: size.width * 0.55,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Logo
                            Image.asset(
                              'assets/images/logo.png',
                              width: size.width * 0.45,
                              height: size.width * 0.45,
                            ),
                            // Role icon badge (bottom-right)
                            Positioned(
                              bottom: size.width * 0.05,
                              right: size.width * 0.07,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  page['icon'] as IconData,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1.0, 1.0),
                              duration: 500.ms,
                              curve: Curves.easeOut,
                            ),

                        const SizedBox(height: 48),

                        // Label chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            page['label'] as String,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: ZippaColors.textPrimary,
                            height: 1.25,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          page['description'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: ZippaColors.textSecondary,
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 450.ms),
                      ],
                    ),
                  );
                },
              ),
            ),

            // — Bottom: dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: ZippaColors.primary,
                      dotColor: ZippaColors.primary.withValues(alpha: 0.2),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Continue' : 'Get Started',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
