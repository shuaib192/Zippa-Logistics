// ============================================
// 🎓 ONBOARDING SCREEN (onboarding_screen.dart)
//
// Shown to first-time users ONLY.
// 3 pages that explain what the app does:
// 1. "Send Packages" — for customers
// 2. "Earn Money" — for riders
// 3. "Grow Your Business" — for vendors
//
// Uses a PageView (swipeable pages) with dots indicator.
// After the last page, user goes to Role Selection.
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
  // PageController controls which page is shown in the PageView
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding content — each page has an icon, title, and description
  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.local_shipping_rounded,
      'color': ZippaColors.primary,
      'title': 'Send Packages\nAnywhere',
      'description':
          'Send packages across the city with real-time tracking. Fast, easy, and safe delivery at your fingertips.',
    },
    {
      'icon': Icons.monetization_on_rounded,
      'color': ZippaColors.primaryLight,
      'title': 'Earn as\nYou Ride',
      'description':
          'Join as a delivery partner and earn competitive income. Flexible hours, instant payouts, and performance rewards.',
    },
    {
      'icon': Icons.store_rounded,
      'color': ZippaColors.primaryDark,
      'title': 'Grow Your\nBusiness',
      'description':
          'Manage all your business deliveries in one place. Bulk orders, analytics, and dedicated support for vendors.',
    },
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete so it doesn't show again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
    
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/role-select');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top right)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: ZippaColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon in a circle
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 80,
                            color: page['color'] as Color,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: ZippaColors.textPrimary,
                            height: 1.2,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // Description
                        Text(
                          page['description'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: ZippaColors.textSecondary,
                            height: 1.5,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 500.ms),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom section: dots + button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Page indicator dots
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: ZippaColors.primary,
                      dotColor: ZippaColors.primary.withValues(alpha: 0.2),
                      dotHeight: 10,
                      dotWidth: 10,
                      spacing: 8,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          // Go to next page
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Last page — continue to role selection
                          _completeOnboarding();
                        }
                      },
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'Next'
                            : 'Get Started',
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
