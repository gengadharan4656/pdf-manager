import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/tool_scaffold.dart';

class CompressPdfScreen extends ConsumerStatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  ConsumerState<CompressPdfScreen> createState() =>
      _CompressPdfScreenState();
}

class _CompressPdfScreenState
    extends ConsumerState<CompressPdfScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  _CompressionLevel _level = _CompressionLevel.medium;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.first.path != null) {
      setState(() => _selectedPath = result.files.first.path);
    }
  }

  String get _estimatedReduction {
    switch (_level) {
      case _CompressionLevel.low:
        return '~10–20%';
      case _CompressionLevel.medium:
        return '~30–50%';
      case _CompressionLevel.high:
        return '~50–70%';
      case _CompressionLevel.maximum:
        return '~70–85%';
    }
  }

  Future<void> _compress() async {
    if (_selectedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Placeholder – real compression via native / Syncfusion later
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF compressed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Compress PDF',
      icon: Icons.compress,
      description:
      'Reduce PDF file size by compressing images and removing unnecessary data.',
      isProcessing: _isProcessing,
      actionLabel: 'Compress PDF',
      onAction: _compress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File picker
          if (_selectedPath == null)
            _FilePickerTile(onTap: _pickFile)
          else
            _SelectedFileTile(
              path: _selectedPath!,
              onClear: () => setState(() => _selectedPath = null),
            ),

          const SizedBox(height: 20),

          const Text(
            'Compression Level',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),

          ...CompressionLevelOption.values.map(
                (opt) => _CompressionTile(
              option: opt,
              selected: _level == opt.level,
              onTap: () => setState(() => _level = opt.level),
            ),
          ),

          const SizedBox(height: 20),

          // Estimated reduction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated reduction:'),
                    Text(
                      _estimatedReduction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (_selectedPath != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Original size:'),
                      Text(
                        _formatSize(
                            File(_selectedPath!).lengthSync()),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum _CompressionLevel { low, medium, high, maximum }

class CompressionLevelOption {
  static const List<CompressionLevelOption> values = [
    CompressionLevelOption(
      level: _CompressionLevel.low,
      label: 'Low',
      subtitle: 'Best quality, smallest reduction',
      icon: Icons.looks_one,
    ),
    CompressionLevelOption(
      level: _CompressionLevel.medium,
      label: 'Medium',
      subtitle: 'Good quality, moderate reduction',
      icon: Icons.looks_two,
    ),
    CompressionLevelOption(
      level: _CompressionLevel.high,
      label: 'High',
      subtitle: 'Acceptable quality, large reduction',
      icon: Icons.looks_3,
    ),
    CompressionLevelOption(
      level: _CompressionLevel.maximum,
      label: 'Maximum',
      subtitle: 'Lower quality, maximum reduction',
      icon: Icons.whatshot,
    ),
  ];

  final _CompressionLevel level;
  final String label;
  final String subtitle;
  final IconData icon;

  const CompressionLevelOption({
    required this.level,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

// ── LOCAL WIDGETS ─────────────────────────────────────────────

class _FilePickerTile extends StatelessWidget {
  final VoidCallback onTap;

  const _FilePickerTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf),
      title: const Text('Select PDF file'),
      trailing: IconButton(
        icon: const Icon(Icons.attach_file),
        onPressed: onTap,
      ),
      onTap: onTap,
    );
  }
}

class _SelectedFileTile extends StatelessWidget {
  final String path;
  final VoidCallback onClear;

  const _SelectedFileTile({
    required this.path,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').last;
    return ListTile(
      leading:
      const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClear,
      ),
    );
  }
}

class _CompressionTile extends StatelessWidget {
  final CompressionLevelOption option;
  final bool selected;
  final VoidCallback onTap;

  const _CompressionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Theme.of(context)
                          .colorScheme
                          .primary
                          : null,
                    ),
                  ),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color:
                Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}