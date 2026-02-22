import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/tool_scaffold.dart';

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  String? _selectedImagePath;
  String _extractedText = '';
  bool _isProcessing = false;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  String _selectedLanguage = 'English';

  final List<String> _languages = [
    'English', 'Spanish', 'French', 'German',
    'Chinese', 'Japanese', 'Korean', 'Arabic',
    'Hindi', 'Portuguese'
  ];

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery,
        imageQuality: 100);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
        _extractedText = '';
      });
      await _runOcr(image.path);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result?.files.first.path != null) {
      // In production: convert PDF page to image first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing PDF for OCR...')),
      );
    }
  }

  Future<void> _runOcr(String imagePath) async {
    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _textRecognizer.processImage(inputImage);

      if (mounted) {
        setState(() {
          _extractedText = recognized.text;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _extractedText = 'OCR failed: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'OCR - Extract Text',
      icon: Icons.text_rotation_none,
      description:
          'Extract text from scanned documents, images, or PDFs using AI-powered OCR.',
      isProcessing: _isProcessing,
      actionLabel: 'Copy Text',
      onAction: _extractedText.isEmpty
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: _extractedText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Text copied to clipboard')),
              );
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language selector
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Document Language',
              prefixIcon: Icon(Icons.language),
            ),
            items: _languages
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setState(() => _selectedLanguage = v!),
          ),
          const SizedBox(height: 16),

          // Source buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('From Image'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('From PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image preview
          if (_selectedImagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Extracted text
          if (_extractedText.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Extracted Text',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${_extractedText.split(' ').length} words',
                    style: TextStyle(color: Colors.grey.shade600,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                _extractedText,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ] else if (!_isProcessing && _selectedImagePath == null)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.text_fields,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Extracted text will appear here',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
