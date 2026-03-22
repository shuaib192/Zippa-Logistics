import 'package:flutter/material.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

class ProfileSwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileSwitchItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: ZippaColors.textPrimary),
      title: Text(
        label, 
        style: const TextStyle(
          color: ZippaColors.textPrimary, 
          fontWeight: FontWeight.w500,
          fontSize: 14,
        )
      ),
      activeColor: ZippaColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
