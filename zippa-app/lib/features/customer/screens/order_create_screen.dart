// ============================================
// 📦 ORDER CREATE SCREEN (order_create_screen.dart)
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';
import 'package:zippa_app/features/customer/screens/map_picker_screen.dart';
import 'package:zippa_app/features/customer/screens/fare_summary_screen.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text inputs
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedSize = 'small';
  String _selectedType = 'document';

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: const Text('New Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Locations Section
              _SectionHeader(number: '1', title: 'Route Details'),
              _LocationField(
                label: 'Pickup Address',
                controller: _pickupController,
                hint: 'Where should we pick it up?',
                icon: Icons.location_on_rounded,
                color: ZippaColors.primary,
                onTap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerScreen(title: 'Pickup Location')),
                  );
                  if (result != null && mounted) {
                    setState(() { _pickupController.text = result['address']; });
                    if (!mounted) return;
                    context.read<OrderProvider>().setPickup(result['address'], result['lat'], result['lng']);
                  }
                },
              ),
              const SizedBox(height: 12),
              _LocationField(
                label: 'Drop-off Address',
                controller: _dropoffController,
                hint: 'Where is it going?',
                icon: Icons.flag_rounded,
                color: ZippaColors.accent,
                onTap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerScreen(title: 'Drop-off Location')),
                  );
                  if (result != null && mounted) {
                    setState(() { _dropoffController.text = result['address']; });
                    if (!mounted) return;
                    context.read<OrderProvider>().setDropoff(result['address'], result['lat'], result['lng']);
                  }
                },
              ),
              
              const SizedBox(height: 32),
              
              // 2. Package Details Section
              _SectionHeader(number: '2', title: 'Package Info'),
              const Text('Package Size', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _PackageSizeSelector(
                selected: _selectedSize,
                onSelected: (val) => setState(() => _selectedSize = val),
              ),
              const SizedBox(height: 20),
              
              const Text('Package Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _DropdownField(
                value: _selectedType,
                items: const ['document', 'parcel', 'food', 'grocery', 'electronics', 'clothing', 'other'],
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),
              
              _TextField(
                label: 'Brief Description (Optional)',
                controller: _descriptionController,
                hint: 'e.g. Fragile, laptop, etc.',
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // 3. Recipient Section
              _SectionHeader(number: '3', title: 'Recipient Details'),
              _TextField(
                label: "Recipient's Name",
                controller: _recipientNameController,
                hint: 'Who is receiving this?',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _TextField(
                label: "Recipient's Phone",
                controller: _recipientPhoneController,
                hint: 'Enter mobile number',
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.length < 10 ? 'Invalid number' : null,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _handleProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ZippaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Get Fare Estimate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _handleProceed() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<OrderProvider>();
      
      // Update non-location details
      provider.setPackageDetails(_selectedSize, _selectedType, _descriptionController.text);
      provider.setRecipient(_recipientNameController.text, _recipientPhoneController.text);
      
      // Validate locations
      if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select pickup and drop-off locations')),
        );
        return;
      }

      // Show loading and get estimate
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: ZippaColors.primary)),
      );

      final success = await provider.estimateFare();
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FareSummaryScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to get estimate')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  const _SectionHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: ZippaColors.primary, shape: BoxShape.circle),
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZippaColors.textPrimary)),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LocationField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ZippaColors.textSecondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: ZippaColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? hint : controller.text,
                    style: TextStyle(
                      color: controller.text.isEmpty ? ZippaColors.textLight : ZippaColors.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ZippaColors.textLight, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageSizeSelector extends StatelessWidget {
  final String selected;
  final Function(String) onSelected;

  const _PackageSizeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final sizes = [
      {'val': 'small', 'label': 'Small', 'desc': 'Fits in bag', 'icon': Icons.inventory_2_outlined},
      {'val': 'medium', 'label': 'Medium', 'desc': 'Fits on bike', 'icon': Icons.backpack_outlined},
      {'val': 'large', 'label': 'Large', 'desc': 'Need trunk', 'icon': Icons.local_shipping_outlined},
      {'val': 'extra_large', 'label': 'Massive', 'desc': 'Special' , 'icon': Icons.airport_shuttle_outlined},
    ];

    return Row(
      children: sizes.map((s) {
        bool isSelected = selected == s['val'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(s['val'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? ZippaColors.primary : ZippaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? ZippaColors.primary : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(s['icon'] as IconData, color: isSelected ? Colors.white : ZippaColors.textSecondary, size: 24),
                  const SizedBox(height: 6),
                  Text(s['label'] as String, style: TextStyle(color: isSelected ? Colors.white : ZippaColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  const _TextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ZippaColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: ZippaColors.textLight, fontSize: 13),
            filled: true,
            fillColor: ZippaColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ZippaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1), style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
