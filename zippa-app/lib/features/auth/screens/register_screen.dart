// ============================================
// 🎓 REGISTER SCREEN (register_screen.dart)
//
// New users create an account here.
// The role (customer/rider/vendor) is passed from
// the Role Selection screen.
//
// Fields: Full Name, Phone, Email (optional), Password
// On success → Navigate to dashboard
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the Terms & Conditions'),
          backgroundColor: ZippaColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Get the role passed from Role Selection screen
    final role = ModalRoute.of(context)?.settings.arguments as String? ?? 'customer';
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.register(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      password: _passwordController.text,
      role: role,
    );
    
    if (!mounted) return;
    
    if (success) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
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
    
    // Role-specific UI elements
    final roleLabels = {
      'customer': {'title': 'Create Your\nAccount ✨', 'subtitle': 'Start sending packages today'},
      'rider': {'title': 'Join Our\nRider Team 🏍️', 'subtitle': 'Start earning with every delivery'},
      'vendor': {'title': 'Register Your\nBusiness 🏪', 'subtitle': 'Manage deliveries like a pro'},
    };
    
    final roleInfo = roleLabels[role] ?? roleLabels['customer']!;

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
                // Header with role-specific text
                Text(
                  roleInfo['title']!,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ZippaColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 8),
                Text(
                  roleInfo['subtitle']!,
                  style: TextStyle(fontSize: 16, color: ZippaColors.textSecondary),
                ).animate().fadeIn(delay: 200.ms),
                
                // Role badge
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ZippaColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Registering as ${role[0].toUpperCase()}${role.substring(1)}',
                    style: TextStyle(
                      color: ZippaColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 32),
                
                // Full Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_rounded, color: ZippaColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Name is required';
                    if (value.length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 16),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '08012345678',
                    prefixIcon: Icon(Icons.phone_rounded, color: ZippaColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Phone number is required';
                    if (value.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 16),
                
                // Email (optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.email_rounded, color: ZippaColors.primary),
                  ),
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 16),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Min 8 characters',
                    prefixIcon: Icon(Icons.lock_rounded, color: ZippaColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: ZippaColors.textLight,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 8) return 'Must be at least 8 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 16),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: ZippaColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: ZippaColors.textLight,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 16),
                
                // Terms & Conditions checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) => setState(() => _agreeToTerms = value!),
                      activeColor: ZippaColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: ZippaColors.textSecondary, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                
                const SizedBox(height: 24),
                
                // Register button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleRegister,
                        child: auth.isLoading
                            ? SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text('Create Account'),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.05, end: 0),
                
                const SizedBox(height: 16),
                
                // Already have account?
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: ZippaColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold),
                          ),
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
