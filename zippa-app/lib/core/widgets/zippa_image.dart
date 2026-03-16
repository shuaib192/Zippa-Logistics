import 'dart:convert';
import 'package:flutter/material.dart';

class ZippaImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ZippaImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildError('Empty/Null URL');
    }

    // Check if it's a base64 data URI
    if (imageUrl!.startsWith('data:image')) {
      try {
        final base64String = imageUrl!.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildError('Base64 error'),
        );
      } catch (e) {
        return _buildError('Base64 catch');
      }
    }

    // Regular network image
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('🖼️ Image Error [$imageUrl]: $error');
        return _buildError('Native network error');
      },
    );
  }

  static ImageProvider provider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage('assets/images/placeholder.png'); // Fallback
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return const AssetImage('assets/images/placeholder.png');
      }
    }

    return NetworkImage(imageUrl);
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError([String? reason]) {
    if (reason != null) debugPrint('❌ Image failed: $reason');
    return errorWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
