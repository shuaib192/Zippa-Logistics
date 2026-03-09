import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/auth/providers/auth_provider.dart';

class RiderEditProfileScreen extends StatefulWidget {
  const RiderEditProfileScreen({super.key});

  @override
  State<RiderEditProfileScreen> createState() => _RiderEditProfileScreenState();
}

class _RiderEditProfileScreenState extends State<RiderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountNameController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.fullName);
    _vehicleTypeController = TextEditingController(text: user?.vehicleType);
    _vehiclePlateController = TextEditingController(text: user?.vehiclePlate);
    _bankNameController = TextEditingController(text: user?.payoutBankName);
    _accountNumberController = TextEditingController(text: user?.payoutAccountNumber);
    _accountNameController = TextEditingController(text: user?.payoutAccountName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile({
      'fullName': _nameController.text,
      'vehicleType': _vehicleTypeController.text,
      'vehiclePlate': _vehiclePlateController.text,
      'payoutBankName': _bankNameController.text,
      'payoutAccountNumber': _accountNumberController.text,
      'payoutAccountName': _accountNameController.text,
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Failed to update profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: const Text('Edit Rider Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ZippaColors.primary)),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Full Name', Icons.person_outline),
              
              const SizedBox(height: 32),
              const Text('Vehicle Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ZippaColors.primary)),
              const SizedBox(height: 16),
              _buildTextField(_vehicleTypeController, 'Vehicle Type (e.g. Motorcycle)', Icons.directions_bike_rounded),
              const SizedBox(height: 16),
              _buildTextField(_vehiclePlateController, 'License Plate', Icons.badge_outlined),

              const SizedBox(height: 32),
              const Text('Banking Details (For Payouts)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ZippaColors.primary)),
              const SizedBox(height: 16),
              _buildTextField(_bankNameController, 'Bank Name', Icons.account_balance_rounded),
              const SizedBox(height: 16),
              _buildTextField(_accountNumberController, 'Account Number', Icons.numbers_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_accountNameController, 'Account Name', Icons.badge_rounded),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZippaColors.primary,
                    iconColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
    );
  }
}
