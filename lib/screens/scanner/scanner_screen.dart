import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _flashOn = false;
  bool _autoCapture = false;
  int _captureCount = 0;
  final List<String> _capturedImages = [];
  late AnimationController _captureAnimController;
  late Animation<double> _captureAnim;

  // Quality modes
  ResolutionPreset _resolution = ResolutionPreset.high;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _captureAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _captureAnimController, curve: Curves.easeInOut),
    );
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Use back camera
    final backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      backCamera,
      _resolution,
      enableAudio: false, // No audio needed, saves power
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);

      // Enable auto focus
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _disposeCamera() {
    _controller?.dispose();
    _controller = null;
    if (mounted) setState(() => _isInitialized = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureAnimController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    _captureAnimController.forward().then((_) => _captureAnimController.reverse());

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      final xFile = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(xFile.path);
        _captureCount++;
        _isCapturing = false;
      });

      // Navigate to crop screen for latest capture
      if (mounted) {
        context.push('/crop', extra: {'imagePath': xFile.path});
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 95);

    if (images.isNotEmpty && mounted) {
      if (images.length == 1) {
        context.push('/crop', extra: {'imagePath': images.first.path});
      } else {
        // Multiple images - go directly to processing
        setState(() {
          _capturedImages.addAll(images.map((e) => e.path));
        });
        _proceedToSave();
      }
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    setState(() => _flashOn = !_flashOn);
    await _controller!.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  void _proceedToSave() {
    if (_capturedImages.isEmpty) return;
    // Navigate to batch review screen (simplified - goes to first crop)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveBottomSheet(
        imageCount: _capturedImages.length,
        imagePaths: List.from(_capturedImages),
        onSave: (name) async {
          Navigator.pop(context);
          // Would call document service here
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            _buildCameraPreview()
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Overlay UI
          _buildOverlayUI(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onTapDown: (details) => _focusAt(details.localPosition),
      child: CameraPreview(
        _controller!,
        child: _buildScanFrame(),
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: AspectRatio(
        aspectRatio: 210 / 297, // A4 ratio
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Corner markers
              ..._buildCornerMarkers(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const size = 24.0;
    const thickness = 3.0;
    const color = Color(0xFF4CAF50);

    Widget corner({required Alignment alignment,
        bool flipX = false, bool flipY = false}) {
      return Align(
        alignment: alignment,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CornerPainter(color: color, thickness: thickness),
            ),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft),
      corner(alignment: Alignment.topRight, flipX: true),
      corner(alignment: Alignment.bottomLeft, flipY: true),
      corner(alignment: Alignment.bottomRight, flipX: true, flipY: true),
    ];
  }

  void _focusAt(Offset position) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final size = MediaQuery.of(context).size;
      await _controller!.setFocusPoint(Offset(
        position.dx / size.width,
        position.dy / size.height,
      ));
    } catch (_) {}
  }

  Widget _buildOverlayUI() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                Text(
                  _captureCount > 0
                      ? '$_captureCount page${_captureCount > 1 ? 's' : ''}'
                      : 'Scan Document',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        color: _flashOn ? Colors.yellow : Colors.white,
                        size: 28,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _autoCapture = !_autoCapture);
                      },
                      icon: Icon(
                        Icons.auto_mode,
                        color: _autoCapture ? Colors.green : Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Auto capture',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hint text
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Position document within the frame',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          const Spacer(),

          // Bottom controls
          Container(
            padding: const EdgeInsets.only(bottom: 36, top: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
            child: Column(
              children: [
                // Captured thumbnails strip
                if (_capturedImages.isNotEmpty)
                  _buildThumbnailStrip(),

                const SizedBox(height: 16),

                // Capture controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    _ControlButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: _pickFromGallery,
                    ),

                    // Capture button
                    ScaleTransition(
                      scale: _captureAnim,
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: _isCapturing
                                ? Colors.white70
                                : Colors.white,
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.black87, size: 30),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Done button
                    _ControlButton(
                      icon: Icons.check_circle,
                      label: 'Done',
                      color: _capturedImages.isNotEmpty
                          ? Colors.green
                          : Colors.grey,
                      onTap: _capturedImages.isNotEmpty
                          ? _proceedToSave
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _capturedImages.length,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(right: 8),
          width: 48,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white54),
            image: DecorationImage(
              image: FileImage(File(_capturedImages[i])),
              fit: BoxFit.cover,
            ),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                setState(() => _capturedImages.removeAt(i));
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveColor, size: 32),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: effectiveColor, fontSize: 12)),
        ],
      ),
    );
  }
}

// Save bottom sheet
class _SaveBottomSheet extends StatefulWidget {
  final int imageCount;
  final List<String> imagePaths;
  final Function(String name) onSave;

  const _SaveBottomSheet({
    required this.imageCount,
    required this.imagePaths,
    required this.onSave,
  });

  @override
  State<_SaveBottomSheet> createState() => _SaveBottomSheetState();
}

class _SaveBottomSheetState extends State<_SaveBottomSheet> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nameController = TextEditingController(
      text:
          'Scan_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Save ${widget.imageCount} page${widget.imageCount > 1 ? 's' : ''} as PDF',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Document name',
              prefixIcon: Icon(Icons.description),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onSave(_nameController.text),
              icon: const Icon(Icons.save),
              label: const Text('Save PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

// Corner painter
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;

  const _CornerPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
