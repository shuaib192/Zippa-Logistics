// ============================================
// 🎓 LOGIN SCREEN (login_screen.dart)
//
// Users enter their phone number and password to log in.
// On success, they go to their role-specific dashboard.
//
// FORM VALIDATION:
// We check the input BEFORE sending to the server:
// - Phone number required
// - Password required, min 8 chars
// If validation fails, we show error messages inline.
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key — used to validate all form fields at once
  final _formKey = GlobalKey<FormState>();
  
  // Controllers — hold the text typed in each field
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true; // Toggle password visibility
  
  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) return;
    
    // Call the auth provider's login method
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    
    if (!mounted) return;
    
    if (success) {
      // Navigate to the right dashboard based on role
      final role = authProvider.user?.role ?? 'customer';
      String route;
      switch (role) {
        case 'rider':
          route = '/rider-home';
          break;
        case 'vendor':
          route = '/vendor-home';
          break;
        default:
          route = '/customer-home';
      }
      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
      // pushNamedAndRemoveUntil removes all previous screens from the stack
      // so pressing back doesn't go back to login
    } else {
      // Show error as a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: ZippaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Welcome\nBack! 💚',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ZippaColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  'Log in to continue your deliveries',
                  style: TextStyle(
                    fontSize: 16,
                    color: ZippaColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 40),
                
                // Phone number field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '08012345678',
                    prefixIcon: Icon(Icons.phone_rounded, color: ZippaColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null; // null means validation passed
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 20),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  // obscureText = hides the text (shows dots instead)
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_rounded, color: ZippaColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: ZippaColors.textLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 12),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Password reset coming soon!')),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: ZippaColors.primary),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login button
                Consumer<AuthProvider>(
                  // Consumer rebuilds only THIS widget when AuthProvider changes
                  builder: (context, auth, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        // Disable button while loading
                        child: auth.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Login'),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 24),
                
                // Don't have an account?
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/role-select');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: ZippaColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: ZippaColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
