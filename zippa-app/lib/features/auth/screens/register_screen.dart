// ============================================
// REGISTER SCREEN — Professional, no emojis
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _agreeToTerms    = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Conditions to continue.'),
          backgroundColor: ZippaColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final role = ModalRoute.of(context)?.settings.arguments as String? ?? 'customer';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final verificationData = await authProvider.register(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      password: _passwordController.text,
      role: role,
    );

    if (!mounted) return;

    if (verificationData != null) {
      // Go to Email Verification screen
      Navigator.pushNamed(
        context, 
        '/verify-email', 
        arguments: {
          'userId': verificationData['userId'],
          'email': verificationData['email'],
          'role': role,
        }
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed. Please try again.'),
          backgroundColor: ZippaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ModalRoute.of(context)?.settings.arguments as String? ?? 'customer';

    final roleTitles = {
      'customer': 'Create Your Account',
      'rider': 'Join as a Rider',
      'vendor': 'Register Your Business',
    };
    final roleSubs = {
      'customer': 'Start sending packages today',
      'rider': 'Start delivering and earning',
      'vendor': 'Manage business deliveries at scale',
    };

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/logo.png', height: 44, width: 44)
                    .animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                Text(roleTitles[role]!,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary))
                    .animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 4),

                Text(roleSubs[role]!,
                    style: const TextStyle(fontSize: 14, color: ZippaColors.textSecondary))
                    .animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 8),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: ZippaColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${role[0].toUpperCase()}${role.substring(1)} Account',
                    style: const TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 28),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: ZippaColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Full name is required';
                    if (v.length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '08012345678',
                    prefixIcon: Icon(Icons.phone_outlined, color: ZippaColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone number is required';
                    if (v.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // Email (required for verification)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.email_outlined, color: ZippaColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required for verification';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimum 8 characters',
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
                    if (v.length < 8) return 'Must be at least 8 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: ZippaColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: ZippaColors.textLight,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 16),

                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (v) => setState(() => _agreeToTerms = v!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 13),
                            children: const [
                              TextSpan(text: 'Terms & Conditions', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600)),
                              TextSpan(text: ' and '),
                              TextSpan(text: 'Privacy Policy', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 22),

                // Register button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Create Account'),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: const TextStyle(color: ZippaColors.textSecondary, fontSize: 14),
                        children: const [
                          TextSpan(text: 'Login', style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
