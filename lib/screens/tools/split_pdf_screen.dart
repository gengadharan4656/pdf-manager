import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/tool_scaffold.dart';
import '../../services/document_service.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  _SplitMode _splitMode = _SplitMode.everyPage;
  int _splitEvery = 1;
  final _rangesController = TextEditingController(text: '1-3, 4-6');

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.first.path != null) {
      setState(() => _selectedPath = result.files.first.path);
    }
  }

  Future<void> _split() async {
    if (_selectedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    // Simulate split operation
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PDF split successfully!'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Split PDF',
      icon: Icons.call_split,
      description:
          'Split a PDF into separate files by page range, every N pages, or extract specific pages.',
      isProcessing: _isProcessing,
      actionLabel: 'Split PDF',
      onAction: _split,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File picker
          if (_selectedPath == null)
            _FilePicker(onTap: _pickFile)
          else
            _SelectedFile(
                path: _selectedPath!, onClear: () => setState(() => _selectedPath = null)),
          const SizedBox(height: 20),

          // Split mode
          const Text('Split Mode',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),

          ...['Every page', 'Every N pages', 'By range'].asMap().entries.map(
            (e) => RadioListTile<_SplitMode>(
              value: _SplitMode.values[e.key],
              groupValue: _splitMode,
              title: Text(e.value),
              onChanged: (v) => setState(() => _splitMode = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),

          if (_splitMode == _SplitMode.everyN) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Split every '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (v) =>
                        _splitEvery = int.tryParse(v) ?? 1,
                  ),
                ),
                const Text(' pages'),
              ],
            ),
          ],

          if (_splitMode == _SplitMode.byRange) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _rangesController,
              decoration: const InputDecoration(
                labelText: 'Page ranges (e.g. 1-3, 4-6, 7)',
                helperText: 'Separate ranges with commas',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _SplitMode { everyPage, everyN, byRange }

class _FilePicker extends StatelessWidget {
  final VoidCallback onTap;

  const _FilePicker({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              width: 2,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file,
                  color: Theme.of(context).colorScheme.primary, size: 32),
              const SizedBox(height: 6),
              Text('Tap to select PDF',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
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
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.red),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
