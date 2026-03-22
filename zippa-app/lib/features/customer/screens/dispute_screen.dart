import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/features/customer/providers/order_provider.dart';

class DisputeScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const DisputeScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedReason = 'item_not_received';

  final List<Map<String, String>> _reasons = [
    {'val': 'item_not_received', 'label': 'Item not received'},
    {'val': 'damaged_item', 'label': 'Item is damaged'},
    {'val': 'rider_behavior', 'label': 'Rider behavior issue'},
    {'val': 'wrong_item', 'label': 'Wrong item delivered'},
    {'val': 'other', 'label': 'Other issue'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitDispute() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await provider.raiseDispute(
        widget.orderId,
        _selectedReason,
        _descriptionController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispute raised successfully. We will contact you soon.')),
          );
          Navigator.pop(context); // Return to tracking
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Failed to raise dispute')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZippaColors.background,
      appBar: AppBar(
        title: const Text('Raise Dispute', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Disputing Order #${widget.orderNumber}. This will pause the payment release until resolved.',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('What is the issue?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ..._reasons.map((reason) => RadioListTile<String>(
                title: Text(reason['label']!),
                value: reason['val']!,
                groupValue: _selectedReason,
                activeColor: ZippaColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _selectedReason = val!),
              )),
              const SizedBox(height: 24),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                validator: (val) => val == null || val.isEmpty ? 'Please describe the issue' : null,
                decoration: InputDecoration(
                  hintText: 'Provide as much detail as possible...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitDispute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZippaColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Submit Dispute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
