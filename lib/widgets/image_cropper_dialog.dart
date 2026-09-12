import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ImageCropperDialog extends StatefulWidget {
  final File imageFile;

  const ImageCropperDialog({super.key, required this.imageFile});

  /// Opens the interactive cropping dialog and returns the cropped image file path.
  static Future<String?> openCropper(
      BuildContext context, File imageFile) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImageCropperDialog(imageFile: imageFile),
    );
  }

  @override
  State<ImageCropperDialog> createState() => _ImageCropperDialogState();
}

class _ImageCropperDialogState extends State<ImageCropperDialog> {
  final GlobalKey _cropBoundaryKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();
  int _quarterTurns = 0;
  bool _isProcessing = false;

  void _rotateClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _resetCrop() {
    setState(() {
      _quarterTurns = 0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _cropBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.pop(context, null);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.pop(context, null);
        return;
      }

      final buffer = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final croppedPath =
          '${tempDir.path}/cropped_profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(buffer);

      if (mounted) {
        Navigator.pop(context, croppedPath);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        Navigator.pop(context, null);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog.fullscreen(
      backgroundColor: isDark ? Colors.black : const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF18181B) : const Color(0xFF1E293B),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context, null),
                    tooltip: 'Cancel',
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Crop & Adjust Profile Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.rotate_right_rounded,
                        color: Colors.white),
                    onPressed: _rotateClockwise,
                    tooltip: 'Rotate 90°',
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded,
                        color: Colors.white),
                    onPressed: _resetCrop,
                    tooltip: 'Reset',
                  ),
                ],
              ),
            ),

            // Instruction Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
              child: const Text(
                'Pinch to zoom and drag to position inside the circle avatar frame',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
              ),
            ),

            // Crop Viewport Center Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RepaintBoundary(
                        key: _cropBoundaryKey,
                        child: ClipOval(
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              border: Border.all(
                                color: Colors.cyan,
                                width: 2,
                              ),
                            ),
                            child: InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              clipBehavior: Clip.hardEdge,
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: RotatedBox(
                                quarterTurns: _quarterTurns,
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.all(20),
              color: isDark ? const Color(0xFF18181B) : const Color(0xFF1E293B),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _cropAndSave,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.crop_rounded, size: 18),
                      label: Text(
                        _isProcessing ? 'Cropping...' : 'Crop & Save',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
