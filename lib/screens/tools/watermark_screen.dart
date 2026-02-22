// watermark_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tool_scaffold.dart';
import '../../services/document_service.dart';
import 'split_pdf_screen.dart';

class WatermarkScreen extends ConsumerStatefulWidget {
  const WatermarkScreen({super.key});

  @override
  ConsumerState<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends ConsumerState<WatermarkScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  final _textController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.3;
  double _rotation = -45;
  Color _color = Colors.grey;
  double _fontSize = 60;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null) {
      setState(() => _selectedPath = result!.files.first.path);
    }
  }

  Future<void> _apply() async {
    if (_selectedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(documentServiceProvider);
      final doc = await service.addWatermark(
        pdfPath: _selectedPath!,
        watermarkText: _textController.text,
        opacity: _opacity,
        rotation: _rotation * (3.14159 / 180),
        colorValue: _color.value,
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watermark added!'),
              backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Add Watermark',
      icon: Icons.branding_watermark,
      description: 'Add a text watermark to all pages of your PDF.',
      isProcessing: _isProcessing,
      actionLabel: 'Apply Watermark',
      onAction: _apply,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!,
            onClear: () => setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        TextField(controller: _textController,
          decoration: const InputDecoration(labelText: 'Watermark text',
              prefixIcon: Icon(Icons.text_fields))),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Color: '),
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) =>
                AlertDialog(
                  title: const Text('Pick color'),
                  content: ColorPicker(pickerColor: _color,
                      onColorChanged: (c) => setState(() => _color = c)),
                  actions: [TextButton(onPressed: () => Navigator.pop(context),
                      child: const Text('Done'))],
                )),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: _color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300))),
          ),
        ]),
        const SizedBox(height: 16),
        Text('Opacity: ${(_opacity * 100).round()}%'),
        Slider(value: _opacity, min: 0.05, max: 1.0,
            onChanged: (v) => setState(() => _opacity = v)),
        Text('Rotation: ${_rotation.round()}°'),
        Slider(value: _rotation, min: -180, max: 180,
            onChanged: (v) => setState(() => _rotation = v)),
        // Preview
        Container(height: 120, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)),
          child: Center(
            child: Transform.rotate(
              angle: _rotation * (3.14159 / 180),
              child: Text(_textController.text,
                style: TextStyle(fontSize: 32, color: _color.withOpacity(_opacity),
                    fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ]),
    );
  }
}

// page_numbers_screen.dart
class PageNumbersScreen extends ConsumerStatefulWidget {
  const PageNumbersScreen({super.key});

  @override
  ConsumerState<PageNumbersScreen> createState() => _PageNumbersScreenState();
}

class _PageNumbersScreenState extends ConsumerState<PageNumbersScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  String _position = 'bottom-center';
  String _format = 'Page {n} of {total}';
  double _fontSize = 12;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  Future<void> _apply() async {
    if (_selectedPath == null) return;
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(documentServiceProvider);
      final doc = await service.addPageNumbers(
        pdfPath: _selectedPath!,
        position: _position,
        format: _format,
        fontSize: _fontSize,
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page numbers added!'),
              backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Add Page Numbers',
      icon: Icons.format_list_numbered,
      description: 'Add page numbers to your PDF document.',
      isProcessing: _isProcessing,
      actionLabel: 'Add Page Numbers',
      onAction: _apply,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!,
            onClear: () => setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        const Text('Position', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final pos in ['bottom-center', 'bottom-right',
            'bottom-left', 'top-center', 'top-right'])
            ChoiceChip(label: Text(pos.split('-').map((e) =>
                '${e[0].toUpperCase()}${e.substring(1)}').join(' ')),
              selected: _position == pos,
              onSelected: (_) => setState(() => _position = pos)),
        ]),
        const SizedBox(height: 16),
        const Text('Format', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final fmt in ['Page {n} of {total}', '{n}', '{n}/{total}',
            'Page {n}'])
            ChoiceChip(label: Text(fmt), selected: _format == fmt,
              onSelected: (_) => setState(() => _format = fmt)),
        ]),
        const SizedBox(height: 16),
        Text('Font Size: ${_fontSize.round()}pt'),
        Slider(value: _fontSize, min: 8, max: 24,
            onChanged: (v) => setState(() => _fontSize = v)),
      ]),
    );
  }
}

// password_screen.dart
class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  bool _isProtectMode = true;
  final _userPassCtrl = TextEditingController();
  final _ownerPassCtrl = TextEditingController();
  bool _obscureUser = true;
  bool _obscureOwner = true;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.first.path != null)
      setState(() => _selectedPath = result!.files.first.path);
  }

  Future<void> _apply() async {
    if (_selectedPath == null || _userPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and enter a password')));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(documentServiceProvider);
      final doc = await service.passwordProtect(
        pdfPath: _selectedPath!,
        userPassword: _userPassCtrl.text,
        ownerPassword: _ownerPassCtrl.text.isEmpty
            ? _userPassCtrl.text : _ownerPassCtrl.text,
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password protection added!'),
              backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: _isProtectMode ? 'Password Protect PDF' : 'Unlock PDF',
      icon: _isProtectMode ? Icons.lock : Icons.lock_open,
      description: _isProtectMode
          ? 'Encrypt your PDF with a password to prevent unauthorized access.'
          : 'Remove password protection from a PDF file.',
      isProcessing: _isProcessing,
      actionLabel: _isProtectMode ? 'Protect PDF' : 'Unlock PDF',
      onAction: _apply,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Mode toggle
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => setState(() => _isProtectMode = true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _isProtectMode ? null : Colors.grey.shade200,
                foregroundColor: _isProtectMode ? null : Colors.black87),
            child: const Text('Protect'),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(
            onPressed: () => setState(() => _isProtectMode = false),
            style: ElevatedButton.styleFrom(
                backgroundColor: !_isProtectMode ? null : Colors.grey.shade200,
                foregroundColor: !_isProtectMode ? null : Colors.black87),
            child: const Text('Unlock'),
          )),
        ]),
        const SizedBox(height: 16),
        if (_selectedPath == null) _FilePicker(onTap: _pickFile)
        else _SelectedFile(path: _selectedPath!,
            onClear: () => setState(() => _selectedPath = null)),
        const SizedBox(height: 16),
        TextField(controller: _userPassCtrl,
          obscureText: _obscureUser,
          decoration: InputDecoration(
            labelText: _isProtectMode ? 'User Password' : 'Current Password',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(_obscureUser ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureUser = !_obscureUser),
            ),
          )),
        if (_isProtectMode) ...[
          const SizedBox(height: 12),
          TextField(controller: _ownerPassCtrl,
            obscureText: _obscureOwner,
            decoration: InputDecoration(
              labelText: 'Owner Password (optional)',
              helperText: 'Controls editing permissions',
              prefixIcon: const Icon(Icons.admin_panel_settings),
              suffixIcon: IconButton(
                icon: Icon(_obscureOwner ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureOwner = !_obscureOwner),
              ),
            )),
        ],
      ]),
    );
  }
}

// Helper widgets
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
