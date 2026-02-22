import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/document_service.dart';

class CropScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  late String _currentImagePath;
  bool _isProcessing = false;
  bool _autoCropApplied = false;

  // Manual crop handles
  Offset _topLeft = const Offset(0.1, 0.1);
  Offset _topRight = const Offset(0.9, 0.1);
  Offset _bottomLeft = const Offset(0.1, 0.9);
  Offset _bottomRight = const Offset(0.9, 0.9);

  // Filter settings
  _FilterMode _filterMode = _FilterMode.auto;
  double _brightness = 0.0;
  double _contrast = 1.0;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _applyAutoCrop();
  }

  Future<void> _applyAutoCrop() async {
    setState(() => _isProcessing = true);
    try {
      // Simulate edge detection - in production integrate native edge detection
      await Future.delayed(const Duration(milliseconds: 800));

      // Auto-detect edges (simplified heuristic, replace with actual ML)
      setState(() {
        _topLeft = const Offset(0.05, 0.05);
        _topRight = const Offset(0.95, 0.05);
        _bottomLeft = const Offset(0.05, 0.95);
        _bottomRight = const Offset(0.95, 0.95);
        _autoCropApplied = true;
        _isProcessing = false;
      });
    } catch (_) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _openManualCropper() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: _currentImagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: const Color(0xFF1565C0),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: const Color(0xFF1565C0),
          dimmedLayerColor: Colors.black87,
          cropFrameColor: const Color(0xFF4CAF50),
          cropGridColor: Colors.white24,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Crop Document',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          showActivitySheetOnDone: false,
          showCancelConfirmationDialog: false,
        ),
      ],
    );

    if (cropped != null && mounted) {
      setState(() => _currentImagePath = cropped.path);
    }
  }

  Future<void> _applyFilter(_FilterMode mode) async {
    setState(() {
      _filterMode = mode;
      _isProcessing = true;
    });

    try {
      final imageBytes = await File(_currentImagePath).readAsBytes();
      final image = img.decodeImage(imageBytes)!;

      img.Image processed;
      switch (mode) {
        case _FilterMode.auto:
          processed = img.adjustColor(image, contrast: 1.3, brightness: 5);
          break;
        case _FilterMode.bw:
          processed = img.grayscale(image);
          processed = img.contrast(processed, contrast: 150);
          break;
        case _FilterMode.color:
          processed = img.adjustColor(image, saturation: 1.2, contrast: 1.1);
          break;
        case _FilterMode.original:
          processed = image;
          break;
      }

      // Save processed image
      final dir = Directory(_currentImagePath).parent.path;
      final filename = '${DateTime.now().millisecondsSinceEpoch}_filtered.jpg';
      final newPath = '$dir/$filename';
      await File(newPath).writeAsBytes(img.encodeJpg(processed, quality: 92));

      if (mounted) {
        setState(() {
          _currentImagePath = newPath;
          _isProcessing = false;
        });
      }
    } catch (_) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rotateImage(int degrees) async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await File(_currentImagePath).readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      final rotated = img.copyRotate(image, angle: degrees.toDouble());
      final dir = Directory(_currentImagePath).parent.path;
      final filename = '${DateTime.now().millisecondsSinceEpoch}_rotated.jpg';
      final newPath = '$dir/$filename';
      await File(newPath).writeAsBytes(img.encodeJpg(rotated, quality: 95));

      if (mounted) {
        setState(() {
          _currentImagePath = newPath;
          _isProcessing = false;
        });
      }
    } catch (_) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmAndSave() async {
    setState(() => _isProcessing = true);

    try {
      final docService = ref.read(documentServiceProvider);
      final now = DateTime.now();
      final doc = await docService.imagesToPdf(
        imagePaths: [_currentImagePath],
        outputName:
            'Scan_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
      );

      if (mounted) {
        ref.read(documentsProvider.notifier).addDocument(doc);
        // Navigate back to home
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Adjust & Crop'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _confirmAndSave,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main image with crop overlay
          Expanded(
            child: Stack(
              children: [
                // Image
                Container(
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(_currentImagePath),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),

                // Processing indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text('Processing...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),

                // Auto-crop badge
                if (_autoCropApplied && !_isProcessing)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Auto-cropped',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filter strip
          _buildFilterStrip(),

          // Tool bar
          _buildToolBar(),
        ],
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      height: 72,
      color: Colors.black,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _FilterChip(
            label: 'Auto',
            icon: Icons.auto_awesome,
            selected: _filterMode == _FilterMode.auto,
            onTap: () => _applyFilter(_FilterMode.auto),
          ),
          _FilterChip(
            label: 'B&W',
            icon: Icons.invert_colors,
            selected: _filterMode == _FilterMode.bw,
            onTap: () => _applyFilter(_FilterMode.bw),
          ),
          _FilterChip(
            label: 'Color',
            icon: Icons.color_lens,
            selected: _filterMode == _FilterMode.color,
            onTap: () => _applyFilter(_FilterMode.color),
          ),
          _FilterChip(
            label: 'Original',
            icon: Icons.image,
            selected: _filterMode == _FilterMode.original,
            onTap: () => _applyFilter(_FilterMode.original),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFF1A1A1A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolButton(
            icon: Icons.crop,
            label: 'Crop',
            onTap: _openManualCropper,
          ),
          _ToolButton(
            icon: Icons.rotate_left,
            label: 'Rotate L',
            onTap: () => _rotateImage(-90),
          ),
          _ToolButton(
            icon: Icons.rotate_right,
            label: 'Rotate R',
            onTap: () => _rotateImage(90),
          ),
          _ToolButton(
            icon: Icons.flip,
            label: 'Flip',
            onTap: () => _rotateImage(180),
          ),
          _ToolButton(
            icon: Icons.auto_fix_high,
            label: 'Auto-Fix',
            onTap: _applyAutoCrop,
          ),
        ],
      ),
    );
  }
}

enum _FilterMode { auto, bw, color, original }

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
