import 'dart:typed_data';

import 'package:flutter/material.dart';

class ScanImageView extends StatelessWidget {
  const ScanImageView({
    super.key,
    this.imageBytes,
    this.imagePath,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_not_supported_outlined,
  });

  final Uint8List? imageBytes;
  final String? imagePath;
  final BoxFit fit;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, fit: fit);
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(placeholderIcon),
    );
  }
}
