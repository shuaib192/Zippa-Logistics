// ============================================
// EMAIL VERIFICATION SCREEN
// Shows OTP input after registration
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  @override
  void dispose() {
    for (var c in _otpControllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otpCode.length < 6) {
      setState(() => _error = 'Please enter the full 6-digit code');
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final response = await _api.post('/auth/verify-email', {
        'userId': args['userId'],
        'otp': _otpCode,
      }, auth: false);

      if (!mounted) return;

      if (response['success'] == true) {
        // Save auth data using AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.completeAuth(response['data']);

        final role = args['role'] ?? 'customer';
        String route;
        switch (role) {
          case 'rider':  route = '/rider-home'; break;
          case 'vendor': route = '/vendor-home'; break;
          default:       route = '/customer-home';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Email verified!'),
            backgroundColor: ZippaColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
      } else {
        setState(() { _error = response['message'] ?? 'Invalid code'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error. Please try again.'; _isLoading = false; });
    }
  }

  Future<void> _resendOTP() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    setState(() { _isResending = true; _error = null; });

    try {
      final response = await _api.post('/auth/resend-otp', {
        'userId': args['userId'],
      }, auth: false);

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New verification code sent!'),
            backgroundColor: ZippaColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() => _error = response['message']);
      }
    } catch (e) {
      setState(() => _error = 'Failed to resend code');
    }
    setState(() => _isResending = false);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args?['email'] ?? '';

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: ZippaColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.email_outlined, color: ZippaColors.primary, size: 36),
              ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),

              const SizedBox(height: 24),

              const Text('Check Your Email',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 8),

              Text('We sent a 6-digit code to\n$email',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: ZippaColors.textSecondary, height: 1.5),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              // OTP Input
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) => Container(
                      width: 44, height: 52, // Slightly smaller for better fit
                      margin: EdgeInsets.only(left: i > 0 ? 6 : 0),
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
                          fillColor: _otpControllers[i].text.isNotEmpty
                              ? ZippaColors.primary.withOpacity(0.08)
                              : ZippaColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _otpControllers[i].text.isNotEmpty ? ZippaColors.primary : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: ZippaColors.primary, width: 2),
                          ),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (val) {
                          setState(() {});
                          if (val.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          }
                          if (val.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          if (_otpCode.length == 6) _verifyOTP();
                        },
                      ),
                    )),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: ZippaColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: ZippaColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: ZippaColors.error, fontSize: 13))),
                  ]),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Verify Email'),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't get the code? ",
                    style: TextStyle(color: ZippaColors.textSecondary, fontSize: 14)),
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: _isResending
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ZippaColors.primary))
                        : const Text('Resend Code',
                            style: TextStyle(color: ZippaColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
