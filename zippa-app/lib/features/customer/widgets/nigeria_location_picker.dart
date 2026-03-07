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
  WardData? _selectedWard;
  final TextEditingController _streetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
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
            const Text('1. Select State', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            _buildDropdown<NigeriaLocation>(
              hint: 'Choose State',
              value: _selectedState,
              items: nigeriaStates.map((state) => DropdownMenuItem(value: state, child: Text(state.state))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedState = value;
                  _selectedLga = null;
                  _selectedWard = null;
                });
              },
            ),
            const SizedBox(height: 16),
  
            // 2. LGA SELECTOR
            const Text('2. Select LGA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            _buildDropdown<LgaData>(
              hint: _selectedState == null ? 'Select state first' : 'Choose LGA',
              value: _selectedLga,
              items: _selectedState?.lgas.map((lga) => DropdownMenuItem(value: lga, child: Text(lga.name))).toList(),
              onChanged: _selectedState == null ? null : (value) {
                setState(() {
                  _selectedLga = value;
                  _selectedWard = null;
                });
              },
            ),
            const SizedBox(height: 16),
  
            // 3. WARD/TOWN SELECTOR
            const Text('3. Select Town / Ward', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            _buildDropdown<WardData>(
              hint: _selectedLga == null ? 'Select LGA first' : 'Choose Town/Ward',
              value: _selectedWard,
              items: _selectedLga?.wards.map((ward) => DropdownMenuItem(value: ward, child: Text(ward.name))).toList(),
              onChanged: _selectedLga == null ? null : (value) {
                setState(() {
                  _selectedWard = value;
                });
              },
            ),
            const SizedBox(height: 16),
  
            // 4. STREET/AREA INPUT
            const Text('4. Street / House Number (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),
  
            // 5. CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedState != null && _selectedLga != null && _selectedWard != null)
                  ? () {
                      final street = _streetController.text.trim();
                      final fullAddress = street.isNotEmpty 
                        ? '$street, ${_selectedWard!.name}, ${_selectedLga!.name}, ${_selectedState!.state}'
                        : '${_selectedWard!.name}, ${_selectedLga!.name}, ${_selectedState!.state}';
                      
                      widget.onSelected(fullAddress, _selectedWard!.lat, _selectedWard!.lng);
                      Navigator.pop(context);
                    }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZippaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>>? items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: onChanged == null ? Colors.grey.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(hint),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
