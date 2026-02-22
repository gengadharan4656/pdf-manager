import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/document_service.dart';
import '../../widgets/tool_scaffold.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final List<String> _selectedPaths = [];
  bool _isProcessing = false;
  final _nameController =
  TextEditingController(text: 'Merged_Document');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedPaths.addAll(
          result.files
              .where((f) => f.path != null)
              .map((f) => f.path!),
        );
      });
    }
  }

  Future<void> _merge() async {
    if (_selectedPaths.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 PDFs to merge'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(documentServiceProvider);

      final doc = await service.mergePdfs(
        pdfPaths: _selectedPaths,
        outputName: _nameController.text.trim(),
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);

      if (!mounted) return;

      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDFs merged successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on UnsupportedError catch (_) {
      if (!mounted) return;

      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF merge requires advanced PDF engine (coming soon)',
          ),
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
      title: 'Merge PDFs',
      icon: Icons.merge,
      description:
      'Combine multiple PDF files into a single document. Drag to reorder.',
      isProcessing: _isProcessing,
      actionLabel: 'Merge PDFs',
      onAction: _merge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Output name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Output file name',
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 16),

          // Add files
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add),
              label: const Text('Add PDF Files'),
            ),
          ),
          const SizedBox(height: 16),

          // Selected files
          if (_selectedPaths.isNotEmpty) ...[
            Text(
              '${_selectedPaths.length} files selected',
              style:
              TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedPaths.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _selectedPaths.removeAt(oldIndex);
                  _selectedPaths.insert(newIndex, item);
                });
              },
              itemBuilder: (_, i) {
                final path = _selectedPaths[i];
                final name = path.split('/').last;
                return ListTile(
                  key: ValueKey(path),
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(File(path).lengthSync() / 1024).toStringAsFixed(0)} KB',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => setState(
                              () => _selectedPaths.removeAt(i),
                        ),
                      ),
                      const Icon(Icons.drag_handle,
                          color: Colors.grey),
                    ],
                  ),
                );
              },
            ),
          ] else
            _EmptyFilePicker(
              label: 'No files selected',
              onTap: _pickFiles,
            ),
        ],
      ),
    );
  }
}

// ── LOCAL EMPTY STATE WIDGET ──────────────────────────────────

class _EmptyFilePicker extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptyFilePicker({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to add PDF files',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}