// ============================================
// 🎓 APP CONSTANTS (app_constants.dart)
//
// A place for values that don't change.
// Keeping these in one file means:
// - Easy to find and update
// - No typos from typing URLs everywhere
// - Changes in one place affect the whole app
// ============================================

class AppConstants {
  // App info
  static const String appName = 'Zippa Logistics';
  static const String tagline = 'Fast, Easy and Safe';
  static const String version = '1.0.0';
  
  // Backend API URL
  // FOR PHYSICAL DEVICE: Use your Mac's WiFi IP address
  // Both your phone and Mac must be on the same WiFi network!
  static const String apiBaseUrl = 'http://192.168.0.104:3001/api';
  
  // FOR ANDROID EMULATOR use: 'http://10.0.2.2:3001/api'
  // FOR iOS SIMULATOR use:    'http://localhost:3001/api'
  
  // Local storage keys (for SharedPreferences)
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String onboardingCompleteKey = 'onboarding_complete';
  
  // WhatsApp Support
  static const String whatsappNumber = '+15551502771'; // Replace with real business number later
}
