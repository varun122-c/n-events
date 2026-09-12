import 'dart:io';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final String pathOrUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const UniversalImage({
    super.key,
    required this.pathOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultFallback = Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF27272A) : Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
      ),
    );

    final trimmed = pathOrUrl.trim();
    if (trimmed.isEmpty) {
      return fallback ?? defaultFallback;
    }

    final isNetwork = trimmed.startsWith('http://') || trimmed.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback ?? defaultFallback,
      );
    } else {
      return Image.file(
        File(trimmed),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback ?? defaultFallback,
      );
    }
  }
}
