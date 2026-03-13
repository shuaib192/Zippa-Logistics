// ============================================
// KYC SUBMISSION SCREEN
// For riders and vendors to submit KYC documents
// ============================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/data/api/api_client.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class KYCSubmissionScreen extends StatefulWidget {
  const KYCSubmissionScreen({super.key});
  @override
  State<KYCSubmissionScreen> createState() => _KYCSubmissionScreenState();
}

class _KYCSubmissionScreenState extends State<KYCSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNumberController = TextEditingController();
  final ApiClient _api = ApiClient();
  String? _selectedDocType;
  File? _documentImage;
  bool _isLoading = false;
  String? _error;
  String? _success;

  final _docTypes = [
    {'value': 'nin', 'label': 'National ID (NIN)', 'icon': Icons.credit_card},
    {'value': 'drivers_license', 'label': "Driver's License", 'icon': Icons.directions_car},
    {'value': 'international_passport', 'label': 'International Passport', 'icon': Icons.flight},
    {'value': 'voters_card', 'label': "Voter's Card", 'icon': Icons.how_to_vote},
  ];

  @override
  void dispose() {
    _docNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ZippaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Upload Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ZippaColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.camera_alt_outlined, color: ZippaColors.primary),
            ),
            title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Use your camera', style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ZippaColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.photo_library_outlined, color: ZippaColors.success),
            ),
            title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Select an existing photo', style: TextStyle(fontSize: 12, color: ZippaColors.textSecondary)),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );

    if (choice == null) return;

    final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked != null) {
      setState(() => _documentImage = File(picked.path));
    }
  }

  Future<void> _submitKYC() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDocType == null) {
      setState(() => _error = 'Please select a document type');
      return;
    }

    setState(() { _isLoading = true; _error = null; _success = null; });

    try {
      final response = await _api.postMultipart('/users/kyc', {
        'documentType': _selectedDocType!,
        'documentNumber': _docNumberController.text.trim(),
      }, filePath: _documentImage?.path, fileField: 'document');

      if (!mounted) return;

      if (response['success'] == true) {
        // Refresh user profile to update KYC status
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.fetchProfile();

        setState(() { _success = response['message']; _isLoading = false; });

        // Show success and pop after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to submit'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error. Please try again.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final kycStatus = authProvider.user?.kycStatus ?? 'unverified';

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: const Text('KYC Verification'),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              _buildStatusBanner(kycStatus).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              if (kycStatus == 'pending') ...[
                _buildPendingView(),
              ] else if (kycStatus == 'verified') ...[
                _buildVerifiedView(),
              ] else ...[
                _buildSubmissionForm(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final configs = {
      'unverified': {'color': Colors.orange, 'icon': Icons.warning_amber_rounded, 'text': 'Identity not verified. Submit your documents to unlock all features.'},
      'pending': {'color': ZippaColors.primary, 'icon': Icons.hourglass_top_rounded, 'text': 'Your documents are being reviewed. This usually takes 24-48 hours.'},
      'verified': {'color': ZippaColors.success, 'icon': Icons.verified_rounded, 'text': 'Your identity has been verified. You have full access.'},
      'rejected': {'color': ZippaColors.error, 'icon': Icons.cancel_rounded, 'text': 'Your KYC was rejected. Please resubmit with valid documents.'},
    };
    final config = configs[status] ?? configs['unverified']!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (config['color'] as Color).withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(config['icon'] as IconData, color: config['color'] as Color, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(config['text'] as String,
          style: TextStyle(fontSize: 13, color: config['color'] as Color, fontWeight: FontWeight.w500, height: 1.4))),
      ]),
    );
  }

  Widget _buildPendingView() {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: ZippaColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.hourglass_top_rounded, color: ZippaColors.primary, size: 40),
        ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 20),
        const Text('Under Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Sit tight. We\'ll notify you once your documents are reviewed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ZippaColors.textSecondary, fontSize: 14)),
      ]),
    );
  }

  Widget _buildVerifiedView() {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: ZippaColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.verified_rounded, color: ZippaColors.success, size: 40),
        ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 20),
        const Text('You\'re Verified!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Your identity has been confirmed. All features are unlocked.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ZippaColors.textSecondary, fontSize: 14)),
      ]),
    );
  }

  Widget _buildSubmissionForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit Your Documents',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 4),
          const Text('Choose a valid government-issued ID',
            style: TextStyle(fontSize: 14, color: ZippaColors.textSecondary),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 24),

          // Document Type Selection
          ...List.generate(_docTypes.length, (i) {
            final doc = _docTypes[i];
            final isSelected = _selectedDocType == doc['value'];
            return GestureDetector(
              onTap: () => setState(() => _selectedDocType = doc['value'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? ZippaColors.primary.withOpacity(0.08) : ZippaColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? ZippaColors.primary : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(doc['icon'] as IconData,
                    color: isSelected ? ZippaColors.primary : ZippaColors.textSecondary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(doc['label'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? ZippaColors.primary : ZippaColors.textPrimary,
                    ))),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: ZippaColors.primary, size: 22),
                ]),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 200 + i * 50));
          }),

          const SizedBox(height: 20),

          // Document Number
          TextFormField(
            controller: _docNumberController,
            decoration: const InputDecoration(
              labelText: 'Document Number',
              hintText: 'Enter your document number',
              prefixIcon: Icon(Icons.numbers_rounded, color: ZippaColors.primary),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Document number is required';
              if (v.length < 6) return 'Enter a valid document number';
              return null;
            },
          ).animate().fadeIn(delay: 450.ms),

          const SizedBox(height: 20),

          // Document Photo Upload
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: ZippaColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: _documentImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(children: [
                        Image.file(_documentImage!, fit: BoxFit.cover, width: double.infinity, height: 160),
                        Positioned(top: 8, right: 8, child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        )),
                      ]),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: ZippaColors.primary.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        const Text('Tap to upload document photo',
                          style: TextStyle(color: ZippaColors.textSecondary, fontSize: 13)),
                        const Text('(Optional — JPG, PNG, or PDF)',
                          style: TextStyle(color: ZippaColors.textLight, fontSize: 11)),
                      ],
                    ),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 24),

          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
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

          if (_success != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ZippaColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_outline, color: ZippaColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_success!, style: TextStyle(color: ZippaColors.success, fontSize: 13))),
              ]),
            ),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitKYC,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_isLoading ? 'Submitting...' : 'Submit for Verification'),
            ),
          ).animate().fadeIn(delay: 550.ms),
        ],
      ),
    );
  }
}
