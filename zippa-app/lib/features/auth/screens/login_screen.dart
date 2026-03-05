// ============================================
// LOGIN SCREEN — Professional, no emojis
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
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final role = authProvider.user?.role ?? 'customer';
      String route;
      switch (role) {
        case 'rider':  route = '/rider-home'; break;
        case 'vendor': route = '/vendor-home'; break;
        default:       route = '/customer-home';
      }
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed. Please check your credentials.'),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/logo.png', height: 44, width: 44)
                    .animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 6),

                Text('Log in to continue',
                    style: TextStyle(fontSize: 15, color: ZippaColors.textSecondary))
                    .animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 36),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '08012345678',
                    prefixIcon: const Icon(Icons.phone_outlined, color: ZippaColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone number is required';
                    if (v.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 18),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: ZippaColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: ZippaColors.textLight,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot Password?', style: TextStyle(color: ZippaColors.primary)),
                  ),
                ),

                const SizedBox(height: 8),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Login'),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/role-select'),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: ZippaColors.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(text: 'Sign Up', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold)),
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
