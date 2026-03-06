import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zippa_app/core/theme/app_theme.dart';

void main() {
  setUpAll(() {
    // Disable google_fonts from making HTTP requests in test mode.
    // Without this, Poppins tries to download from fonts.gstatic.com
    // and fails because CI has no internet access to font servers.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('Brand colors are correct navy/cream/green values', () {
    expect(ZippaColors.primary.value, equals(const Color(0xFF0A2A5E).value));
    expect(ZippaColors.primaryDark.value, equals(const Color(0xFF061A3A).value));
    expect(ZippaColors.primaryLight.value, equals(const Color(0xFF1E4C9A).value));
  });

}
