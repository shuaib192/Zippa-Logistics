// ============================================
// RESET PASSWORD SCREEN
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    for (var c in _otpControllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the 6-digit code')));
      return;
    }

    final email = (ModalRoute.of(context)?.settings.arguments as Map?)?['email'] ?? '';
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await auth.resetPassword(
      email: email,
      otp: _otpCode,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset successful! Please login.'),
          backgroundColor: ZippaColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Reset failed'),
          backgroundColor: ZippaColors.error,
          behavior: SnackBarBehavior.floating,
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
                Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 8),

                Text('Enter the 6-digit code sent to your email and your new password',
                    style: TextStyle(fontSize: 14, color: ZippaColors.textSecondary))
                    .animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 32),

                // OTP Label
                const Text('Verification Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ZippaColors.textSecondary)),
                const SizedBox(height: 12),

                // OTP Input Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(6, (i) => Container(
                      width: 44, height: 52,
                      margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                      child: TextFormField(
                        controller: _otpControllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: ZippaColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ZippaColors.primary, width: 2)),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                          if (val.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                        },
                      ),
                    )),
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 32),

                // New Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: ZippaColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: ZippaColors.textLight),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 18),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_reset_rounded, color: ZippaColors.primary),
                  ),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 40),

                Consumer<AuthProvider>(
                  builder: (context, auth, _) => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleReset,
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Reset Password'),
                    ),
                  ),
                ).animate().fadeIn(delay: 550.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
