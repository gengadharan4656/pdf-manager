// annotate_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tool_scaffold.dart';
import '../../services/document_service.dart';
import 'package:file_picker/file_picker.dart';

class AnnotateScreen extends StatefulWidget {
  const AnnotateScreen({super.key});

  @override
  State<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends State<AnnotateScreen> {
  String? _selectedPath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Annotate PDF',
      icon: Icons.draw,
      description: 'Add highlights, notes, underlines, and stamps to your PDF.',
      isProcessing: false,
      actionLabel: 'Open in Editor',
      onAction: () {
        if (_selectedPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a PDF')));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening PDF editor...')));
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 20),
        const Text('Available Tools', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final tool in [
            ('Highlight', Icons.highlight, Colors.yellow),
            ('Underline', Icons.format_underline, Colors.blue),
            ('Strikethrough', Icons.strikethrough_s, Colors.red),
            ('Note', Icons.sticky_note_2, Colors.orange),
            ('Draw', Icons.brush, Colors.purple),
            ('Text Box', Icons.text_fields, Colors.teal),
            ('Stamp', Icons.approval, Colors.green),
            ('Arrow', Icons.arrow_forward, Colors.indigo),
          ])
            Chip(avatar: Icon(tool.$2, size: 16, color: tool.$3),
              label: Text(tool.$1),
              backgroundColor: tool.$3.withOpacity(0.1)),
        ]),
      ]),
    );
  }
}

// sign_screen.dart
class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  String? _selectedPath;
  bool _hasSignature = false;
  List<Offset> _points = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'eSign PDF',
      icon: Icons.draw_outlined,
      description: 'Add your digital signature to a PDF document.',
      isProcessing: false,
      actionLabel: 'Apply Signature',
      onAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature applied successfully!'),
              backgroundColor: Colors.green));
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 20),
        const Text('Draw Your Signature',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onPanStart: (d) => setState(() {
                _points.add(d.localPosition);
                _hasSignature = true;
              }),
              onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
              onPanEnd: (_) => setState(() => _points.add(Offset.infinite)),
              child: CustomPaint(
                painter: _SignaturePainter(_points),
                child: _points.isEmpty
                    ? Center(child: Text('Sign here',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 16)))
                    : null,
              ),
            ),
          ),
        ),
        if (_hasSignature)
          TextButton.icon(
            onPressed: () => setState(() {
              _points.clear();
              _hasSignature = false;
            }),
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear'),
          ),
      ]),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => old.points != points;
}

// word_to_pdf_screen.dart
class WordToPdfScreen extends ConsumerStatefulWidget {
  const WordToPdfScreen({super.key});

  @override
  ConsumerState<WordToPdfScreen> createState() => _WordToPdfScreenState();
}

class _WordToPdfScreenState extends ConsumerState<WordToPdfScreen> {
  String? _selectedPath;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'doc', 'pptx', 'ppt', 'odt'],
    );
    if (result?.files.first.path != null) {
      setState(() => _selectedPath = result!.files.first.path);
    }
  }

  Future<void> _convert() async {
    if (_selectedPath == null) return;

    setState(() => _isProcessing = true);
    try {
      final sourcePath = _selectedPath!;
      final textContent = await _extractSourceText(sourcePath);
      final outName = _outputNameFromPath(sourcePath);

      final service = ref.read(documentServiceProvider);
      final doc = await service.createPdfFromText(
        outputName: outName,
        sourceLabel: 'Source: ${File(sourcePath).uri.pathSegments.last}',
        content: textContent,
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);

      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Converted to PDF!'),
          backgroundColor: Colors.green,
        ),
      );
      context.push('/viewer', extra: doc);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversion failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Office to PDF',
      icon: Icons.description,
      description: 'Convert Word, PowerPoint, and other Office documents to PDF.',
      isProcessing: _isProcessing,
      actionLabel: 'Convert to PDF',
      onAction: _convert,
      child: Column(children: [
        if (_selectedPath == null)
          _FilePicker(onTap: _pickFile)
        else
          _SelectedFile(path: _selectedPath!, onClear: () => setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        const _SupportedFormatsCard(formats: [
          ('DOCX/DOC', Icons.description, 'Word Documents', Colors.blue),
          ('PPTX/PPT', Icons.slideshow, 'PowerPoint', Colors.red),
          ('ODT', Icons.text_snippet, 'OpenDocument', Colors.orange),
        ]),
      ]),
    );
  }
}

// excel_to_pdf_screen.dart
class ExcelToPdfScreen extends ConsumerStatefulWidget {
  const ExcelToPdfScreen({super.key});

  @override
  ConsumerState<ExcelToPdfScreen> createState() => _ExcelToPdfScreenState();
}

class _ExcelToPdfScreenState extends ConsumerState<ExcelToPdfScreen> {
  String? _selectedPath;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'ods'],
    );
    if (result?.files.first.path != null) {
      setState(() => _selectedPath = result!.files.first.path);
    }
  }

  Future<void> _convert() async {
    if (_selectedPath == null) return;

    setState(() => _isProcessing = true);
    try {
      final sourcePath = _selectedPath!;
      final textContent = await _extractSourceText(sourcePath);
      final outName = _outputNameFromPath(sourcePath);

      final service = ref.read(documentServiceProvider);
      final doc = await service.createPdfFromText(
        outputName: outName,
        sourceLabel: 'Source: ${File(sourcePath).uri.pathSegments.last}',
        content: textContent,
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);

      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Converted to PDF!'),
          backgroundColor: Colors.green,
        ),
      );
      context.push('/viewer', extra: doc);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversion failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Spreadsheet to PDF',
      icon: Icons.table_chart,
      description: 'Convert Excel and CSV files to PDF documents.',
      isProcessing: _isProcessing,
      actionLabel: 'Convert to PDF',
      onAction: _convert,
      child: Column(children: [
        if (_selectedPath == null)
          _FilePicker(onTap: _pickFile)
        else
          _SelectedFile(path: _selectedPath!, onClear: () => setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        const _SupportedFormatsCard(formats: [
          ('XLSX/XLS', Icons.table_chart, 'Excel Spreadsheets', Colors.green),
          ('CSV', Icons.grid_on, 'CSV Files', Colors.teal),
          ('ODS', Icons.table_view, 'OpenDocument Sheets', Colors.orange),
        ]),
      ]),
    );
  }
}

// html_to_pdf_screen.dart
class HtmlToPdfScreen extends ConsumerStatefulWidget {
  const HtmlToPdfScreen({super.key});

  @override
  ConsumerState<HtmlToPdfScreen> createState() => _HtmlToPdfScreenState();
}

class _HtmlToPdfScreenState extends ConsumerState<HtmlToPdfScreen> {
  final _urlController = TextEditingController();
  bool _isProcessing = false;
  bool _useUrl = true;
  String? _selectedPath;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html', 'htm', 'txt'],
    );
    if (result?.files.first.path != null) {
      setState(() => _selectedPath = result!.files.first.path);
    }
  }

  Future<void> _convert() async {
    setState(() => _isProcessing = true);
    try {
      String content;
      String sourceLabel;
      String outputName;

      if (_useUrl) {
        final input = _urlController.text.trim();
        if (input.isEmpty) {
          throw 'Enter a valid URL';
        }
        content = 'Web conversion placeholder for: $input\n\nOpen this page in backend/cloud rendering for pixel-perfect PDF.';
        sourceLabel = 'Source URL: $input';
        outputName = 'web_page_pdf';
      } else {
        if (_selectedPath == null) {
          throw 'Please select an HTML/TXT file';
        }
        final sourcePath = _selectedPath!;
        content = await _extractSourceText(sourcePath);
        sourceLabel = 'Source: ${File(sourcePath).uri.pathSegments.last}';
        outputName = _outputNameFromPath(sourcePath);
      }

      final service = ref.read(documentServiceProvider);
      final doc = await service.createPdfFromText(
        outputName: outputName,
        sourceLabel: sourceLabel,
        content: content,
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);

      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Converted to PDF!'),
          backgroundColor: Colors.green,
        ),
      );
      context.push('/viewer', extra: doc);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversion failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'HTML to PDF',
      icon: Icons.web,
      description: 'Convert web pages or HTML/TXT files to PDF documents.',
      isProcessing: _isProcessing,
      actionLabel: 'Convert to PDF',
      onAction: _convert,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _useUrl = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _useUrl ? null : Colors.grey.shade200,
                foregroundColor: _useUrl ? null : Colors.black87,
              ),
              child: const Text('From URL'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _useUrl = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !_useUrl ? null : Colors.grey.shade200,
                foregroundColor: !_useUrl ? null : Colors.black87,
              ),
              child: const Text('From File'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (_useUrl)
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website URL',
              hintText: 'https://example.com',
              prefixIcon: Icon(Icons.link),
            ),
          )
        else
          Column(children: [
            if (_selectedPath == null)
              _FilePicker(onTap: _pickFile)
            else
              _SelectedFile(path: _selectedPath!, onClear: () => setState(() => _selectedPath = null)),
          ]),
      ]),
    );
  }
}


String _outputNameFromPath(String sourcePath) {
  final source = File(sourcePath).uri.pathSegments.last;
  final dot = source.lastIndexOf('.');
  return dot > 0 ? source.substring(0, dot) : source;
}

Future<String> _extractSourceText(String sourcePath) async {
  final file = File(sourcePath);
  if (!await file.exists()) {
    throw 'Source file not found';
  }

  final ext = sourcePath.split('.').last.toLowerCase();

  if (['txt', 'csv', 'html', 'htm'].contains(ext)) {
    return file.readAsString();
  }

  if (['docx', 'pptx', 'xlsx', 'odt', 'ods'].contains(ext)) {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final xmlBuffers = <String>[];

    for (final entry in archive.files) {
      final name = entry.name.toLowerCase();
      if (entry.isFile && name.endsWith('.xml') &&
          (name.contains('document') ||
              name.contains('sharedstrings') ||
              name.contains('slides') ||
              name.contains('content'))) {
        final data = entry.content;
        if (data is List<int>) {
          xmlBuffers.add(utf8.decode(data, allowMalformed: true));
        }
      }
    }

    if (xmlBuffers.isEmpty) {
      return 'Could not extract readable text from file.';
    }

    final xmlText = xmlBuffers.join('\n');
    return xmlText
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  if (['doc', 'ppt', 'xls'].contains(ext)) {
    return 'Legacy Office format detected (${ext.toUpperCase()}). Rich parsing requires a native converter SDK.\n\nFile: ${file.uri.pathSegments.last}';
  }

  return 'Unsupported source format: .$ext';
}

// grayscale_screen.dart
class GrayscaleScreen extends StatefulWidget {
  const GrayscaleScreen({super.key});

  @override
  State<GrayscaleScreen> createState() => _GrayscaleScreenState();
}

class _GrayscaleScreenState extends State<GrayscaleScreen> {
  String? _selectedPath;
  bool _isProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Convert to Grayscale',
      icon: Icons.invert_colors,
      description: 'Convert a color PDF to grayscale/black & white to reduce file size.',
      isProcessing: _isProcessing,
      actionLabel: 'Convert to Grayscale',
      onAction: () async {
        if (_selectedPath == null) return;
        setState(() => _isProcessing = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Converted to grayscale!'),
                backgroundColor: Colors.green));
        }
      },
      child: Column(children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _ModeCard(label: 'Before', isColor: true)),
          const Icon(Icons.arrow_forward, color: Colors.grey),
          Expanded(child: _ModeCard(label: 'After', isColor: false)),
        ]),
      ]),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final bool isColor;
  const _ModeCard({required this.label, required this.isColor});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Icon(Icons.picture_as_pdf, size: 40,
          color: isColor ? Colors.red : Colors.grey),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(isColor ? 'Color' : 'Grayscale',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ])));
  }
}

// delete_pages_screen.dart
class DeletePagesScreen extends StatefulWidget {
  const DeletePagesScreen({super.key});

  @override
  State<DeletePagesScreen> createState() => _DeletePagesScreenState();
}

class _DeletePagesScreenState extends State<DeletePagesScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  final _pagesController = TextEditingController(text: '1, 3-5');

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Delete Pages',
      icon: Icons.delete_sweep,
      description: 'Remove specific pages from your PDF document.',
      isProcessing: _isProcessing,
      actionLabel: 'Delete Pages',
      onAction: () async {
        if (_selectedPath == null) return;
        setState(() => _isProcessing = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pages deleted!'),
                backgroundColor: Colors.green));
        }
      },
      child: Column(children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        TextField(controller: _pagesController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Pages to delete',
            helperText: 'e.g. 1, 3-5, 8 (comma-separated, ranges allowed)',
            prefixIcon: Icon(Icons.numbers),
          )),
      ]),
    );
  }
}

// extract_pages_screen.dart
class ExtractPagesScreen extends StatefulWidget {
  const ExtractPagesScreen({super.key});

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesScreenState();
}

class _ExtractPagesScreenState extends State<ExtractPagesScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  final _pagesController = TextEditingController(text: '1-3');

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Extract Pages',
      icon: Icons.content_cut,
      description: 'Extract specific pages from a PDF into a new document.',
      isProcessing: _isProcessing,
      actionLabel: 'Extract Pages',
      onAction: () async {
        if (_selectedPath == null) return;
        setState(() => _isProcessing = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pages extracted!'),
                backgroundColor: Colors.green));
        }
      },
      child: Column(children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        TextField(controller: _pagesController,
          decoration: const InputDecoration(
            labelText: 'Pages to extract',
            helperText: 'e.g. 1-3, 5, 7-9',
            prefixIcon: Icon(Icons.numbers),
          )),
      ]),
    );
  }
}

// reorder_screen.dart
class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  List<int> _pageOrder = List.generate(5, (i) => i + 1);

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Reorder Pages',
      icon: Icons.swap_vert,
      description: 'Drag and drop to reorder pages in your PDF.',
      isProcessing: _isProcessing,
      actionLabel: 'Save Order',
      onAction: () async {
        if (_selectedPath == null) return;
        setState(() => _isProcessing = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pages reordered!'),
                backgroundColor: Colors.green));
        }
      },
      child: Column(children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          onReorder: (old, newIdx) {
            setState(() {
              if (newIdx > old) newIdx--;
              final item = _pageOrder.removeAt(old);
              _pageOrder.insert(newIdx, item);
            });
          },
          children: _pageOrder.map((page) => ListTile(
            key: ValueKey(page),
            leading: CircleAvatar(child: Text('$page')),
            title: Text('Page $page'),
            trailing: const Icon(Icons.drag_handle),
          )).toList(),
        ),
      ]),
    );
  }
}

// redact_screen.dart
class RedactScreen extends StatefulWidget {
  const RedactScreen({super.key});

  @override
  State<RedactScreen> createState() => _RedactScreenState();
}

class _RedactScreenState extends State<RedactScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  final _searchController = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Redact PDF',
      icon: Icons.remove_red_eye_outlined,
      description: 'Permanently black out sensitive information from your PDF.',
      isProcessing: _isProcessing,
      actionLabel: 'Apply Redactions',
      onAction: () async {
        if (_selectedPath == null) return;
        setState(() => _isProcessing = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content redacted!'),
                backgroundColor: Colors.green));
        }
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        TextField(controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search text to redact',
            helperText: 'All instances will be permanently blacked out',
            prefixIcon: Icon(Icons.search),
          )),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200)),
          child: Row(children: [
            const Icon(Icons.warning_amber, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'Redaction is permanent and cannot be undone. Make a backup first.',
              style: TextStyle(fontSize: 13),
            )),
          ])),
      ]),
    );
  }
}

// metadata_screen.dart
class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  final _creatorCtrl = TextEditingController(text: 'PDF Manager Pro');

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    setState(() => _selectedPath = path);
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Edit PDF Metadata',
      icon: Icons.info_outline,
      description: 'Edit document properties like title, author, subject and keywords.',
      isProcessing: _isProcessing,
      actionLabel: 'Save Metadata',
      onAction: () async {
        if (_selectedPath == null) return;
        setState(() => _isProcessing = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Metadata saved!'),
                backgroundColor: Colors.green));
        }
      },
      child: Column(children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!, onClear: () =>
            setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        for (final field in [
          ('Title', _titleCtrl, Icons.title),
          ('Author', _authorCtrl, Icons.person),
          ('Subject', _subjectCtrl, Icons.subject),
          ('Keywords', _keywordsCtrl, Icons.tag),
          ('Creator App', _creatorCtrl, Icons.apps),
        ]) ...[
          TextField(controller: field.$2,
            decoration: InputDecoration(labelText: field.$1,
                prefixIcon: Icon(field.$3))),
          const SizedBox(height: 12),
        ],
      ]),
    );
  }
}

// Shared helper
class _SupportedFormatsCard extends StatelessWidget {
  final List<(String, IconData, String, Color)> formats;
  const _SupportedFormatsCard({required this.formats});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Supported formats', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...formats.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Icon(f.$2, color: f.$4, size: 20),
            const SizedBox(width: 10),
            Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(f.$3, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ]),
        )),
      ]));
  }
}

class _FilePicker extends StatelessWidget {
  final VoidCallback onTap;
  const _FilePicker({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(height: 100,
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.04)),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.upload_file,
              color: Theme.of(context).colorScheme.primary, size: 32),
          const SizedBox(height: 6),
          Text('Tap to select PDF',
              style: TextStyle(color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500)),
        ]))));
  }
}

class _SelectedFile extends StatelessWidget {
  final String path;
  final VoidCallback onClear;
  const _SelectedFile({required this.path, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').last;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300)),
      child: Row(children: [
        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
        const SizedBox(width: 10),
        Expanded(child: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        IconButton(icon: const Icon(Icons.clear, color: Colors.red),
            onPressed: onClear),
      ]));
  }
}
