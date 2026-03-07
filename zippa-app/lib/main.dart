// ============================================
// 🎓 MAIN.DART — The App Entry Point
//
// This is where EVERYTHING starts.
// When you run "flutter run", Dart executes main() first.
//
// WHAT THIS FILE DOES:
// 1. Wraps the app in Provider(s) for state management
// 2. Configures the app theme (colors, fonts)
// 3. Sets up navigation routes (which URL → which screen)
// 4. Launches the SplashScreen as the first screen
//
// KEY CONCEPTS:
//
// MaterialApp = Flutter's main widget that configures the app
// ChangeNotifierProvider = makes a Provider available to all screens below it
// routes = a map of route names to screen widgets
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Our files
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/customer/screens/customer_home_screen.dart';
import 'features/customer/screens/order_create_screen.dart';
import 'features/rider/screens/rider_home_screen.dart';
import 'features/vendor/screens/vendor_home_screen.dart';
import 'features/customer/providers/order_provider.dart';
import 'core/providers/navigation_provider.dart';

// ============================================
// main() — The very first function that runs
// ============================================
void main() {
  // Ensure Flutter is initialized before running
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set the status bar style (the bar at the top with battery, time, etc.)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,  // Transparent status bar
    statusBarIconBrightness: Brightness.dark,  // Dark icons
  ));
  
  // Launch the app!
  runApp(const ZippaApp());
}

// ============================================
// ZippaApp — The root widget of the entire application
//
// MultiProvider wraps the app so ALL screens can access
// the providers (shared data stores).
// ============================================
class ZippaApp extends StatelessWidget {
  const ZippaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // List of all providers (data stores) for the app
      // As we add more features, we'll add more providers here
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        // App configuration
        title: 'Zippa Logistics',
        debugShowCheckedModeBanner: false,  // Remove the ugly "DEBUG" banner
        
        // Apply our custom theme
        theme: ZippaTheme.lightTheme,
        
        // Start with the Splash Screen
        initialRoute: '/',
        
        // ============================================
        // ROUTES — URL/name to screen mapping
        // When we call Navigator.pushNamed(context, '/login'),
        // Flutter looks up '/login' here and shows LoginScreen.
        // ============================================
        routes: {
          '/':              (_) => const SplashScreen(),
          '/onboarding':    (_) => const OnboardingScreen(),
          '/role-select':   (_) => const RoleSelectionScreen(),
          '/login':         (_) => const LoginScreen(),
          '/register':      (_) => const RegisterScreen(),
          '/customer-home': (_) => const CustomerHomeScreen(),
          '/order-create':  (_) => const OrderCreateScreen(),
          '/rider-home':    (_) => const RiderHomeScreen(),
          '/vendor-home':   (_) => const VendorHomeScreen(),
        },
      ),
    );
  }
}
