import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';
import 'package:zippa_app/data/constants/nigeria_locations.dart';

class NigeriaLocationPicker extends StatefulWidget {
  final String title;
  final Function(String address, double lat, double lng) onSelected;

  const NigeriaLocationPicker({
    super.key,
    required this.title,
    required this.onSelected,
  });

  @override
  State<NigeriaLocationPicker> createState() => _NigeriaLocationPickerState();
}

class _NigeriaLocationPickerState extends State<NigeriaLocationPicker> {
  NigeriaLocation? _selectedState;
  LgaData? _selectedLga;
  final TextEditingController _streetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ZippaColors.primary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          
          // 1. STATE SELECTOR
          const Text('Select State', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<NigeriaLocation>(
                isExpanded: true,
                hint: const Text('Choose State'),
                value: _selectedState,
                items: nigeriaStates.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state.state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    _selectedLga = null; // Reset LGA
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. LGA SELECTOR
          const Text('Select Local Government (LGA)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _selectedState == null ? Colors.grey.shade100 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LgaData>(
                isExpanded: true,
                hint: const Text('Choose LGA'),
                value: _selectedLga,
                disabledHint: const Text('Select state first'),
                items: _selectedState?.lgas.map((lga) {
                  return DropdownMenuItem(
                    value: lga,
                    child: Text(lga.name),
                  );
                }).toList(),
                onChanged: _selectedState == null ? null : (value) {
                  setState(() {
                    _selectedLga = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. STREET/AREA INPUT
          const Text('Area / Street / House Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _streetController,
            decoration: InputDecoration(
              hintText: 'e.g. 15, Allen Avenue',
              filled: true,
              fillColor: Colors.grey.shade50,
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
          const SizedBox(height: 32),

          // 4. CONFIRM BUTTON
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedState != null && _selectedLga != null && _streetController.text.isNotEmpty)
                ? () {
                    final fullAddress = '${_streetController.text}, ${_selectedLga!.name}, ${_selectedState!.state} State';
                    widget.onSelected(fullAddress, _selectedLga!.lat, _selectedLga!.lng);
                    Navigator.pop(context);
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ZippaColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
