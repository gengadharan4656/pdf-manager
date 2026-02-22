import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tool_scaffold.dart';
import '../../services/document_service.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  final List<String> _imagePaths = [];
  bool _isProcessing = false;
  final _nameController = TextEditingController(text: 'Image_PDF');
  bool _fitToPage = true;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 95);
    if (images.isNotEmpty) {
      setState(() => _imagePaths.addAll(images.map((e) => e.path)));
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera,
        imageQuality: 95);
    if (image != null) setState(() => _imagePaths.add(image.path));
  }

  Future<void> _convert() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one image')));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final service = ref.read(documentServiceProvider);
      final doc = await service.imagesToPdf(
        imagePaths: _imagePaths,
        outputName: _nameController.text.trim(),
        fitToPage: _fitToPage,
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF created!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Image to PDF',
      icon: Icons.image,
      description: 'Convert one or multiple images to a PDF document.',
      isProcessing: _isProcessing,
      actionLabel: 'Create PDF',
      onAction: _convert,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _nameController,
          decoration: const InputDecoration(labelText: 'Output file name',
              prefixIcon: Icon(Icons.description))),
        const SizedBox(height: 16),

        // Add images buttons
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            onPressed: _pickFromCamera,
            icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
        ]),
        const SizedBox(height: 12),

        // Settings
        SwitchListTile(
          value: _fitToPage,
          onChanged: (v) => setState(() => _fitToPage = v),
          title: const Text('Fit to page'),
          subtitle: const Text('Scale image to fill A4 page'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const SizedBox(height: 16),

        // Images grid
        if (_imagePaths.isNotEmpty) ...[
          Text('${_imagePaths.length} image${_imagePaths.length > 1 ? 's' : ''} selected',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _imagePaths.length,
            itemBuilder: (_, i) => Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_imagePaths[i]),
                    fit: BoxFit.cover, width: double.infinity,
                    height: double.infinity)),
              Positioned(top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _imagePaths.removeAt(i)),
                  child: Container(width: 22, height: 22,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white)))),
              Positioned(bottom: 4, left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11)))),
            ]),
          ),
        ] else
          Center(
            child: Padding(padding: const EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No images selected', style: TextStyle(color: Colors.grey.shade500)),
              ])),
          ),
      ]),
    );
  }
}
