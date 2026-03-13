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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';

// Our files
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/email_verification_screen.dart';
import 'features/auth/screens/kyc_submission_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/customer/screens/customer_home_screen.dart';
import 'features/customer/screens/order_create_screen.dart';
import 'features/rider/screens/rider_home_screen.dart';
import 'features/customer/screens/customer_notifications_screen.dart';
import 'features/customer/screens/zipbot_screen.dart';
import 'features/customer/providers/order_provider.dart';
import 'features/customer/providers/wallet_provider.dart';
import 'features/customer/providers/notification_provider.dart';
import 'features/customer/providers/marketplace_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/providers/location_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/vendor/providers/vendor_product_provider.dart';
import 'features/vendor/screens/vendor_shell.dart';

// ============================================
// Background FCM Message Handler
// ============================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("📩 Background Message: ${message.messageId}");
}

// ============================================
// main() — The very first function that runs
// ============================================
void main() async {
  // Ensure Flutter is initialized before running
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up background message handling
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize FCM Service (Permissions & Local Notifications)
  await FCMService.initialize();
  
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
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VendorProductProvider()),
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
          '/verify-email':  (_) => const EmailVerificationScreen(),
          '/kyc-submit':    (_) => const KYCSubmissionScreen(),
          '/forgot-password': (_) => const ForgotPasswordScreen(),
          '/reset-password': (_) => const ResetPasswordScreen(),
          '/customer-home': (_) => const CustomerHomeScreen(),
          '/order-create':  (_) => const OrderCreateScreen(),
          '/notifications': (_) => const CustomerNotificationsScreen(),
          '/zipbot':        (_) => const ZipBotScreen(),
          '/rider-home':    (_) => const RiderHomeScreen(),
          '/vendor-home':   (_) => const VendorShell(),
        },
      ),
    );
  }
}
