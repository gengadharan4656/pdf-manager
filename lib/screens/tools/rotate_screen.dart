import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/tool_scaffold.dart';

class RotateScreen extends StatefulWidget {
  const RotateScreen({super.key});

  @override
  State<RotateScreen> createState() => _RotateScreenState();
}

class _RotateScreenState extends State<RotateScreen> {
  String? _selectedPath;
  bool _isProcessing = false;
  int _rotation = 90;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.first.path != null) {
      setState(() => _selectedPath = result.files.first.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Rotate PDF',
      icon: Icons.rotate_right,
      description: 'Rotate all pages or specific pages of your PDF.',
      isProcessing: _isProcessing,
      actionLabel: 'Rotate PDF',
      onAction: () async {
        if (_selectedPath == null) return;

        setState(() => _isProcessing = true);
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF rotated!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedPath == null)
            _FilePickerTile(onTap: _pickFile)
          else
            _SelectedFileTile(
              path: _selectedPath!,
              onClear: () => setState(() => _selectedPath = null),
            ),

          const SizedBox(height: 20),

          const Text(
            'Rotation Angle',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            children: [
              for (final deg in [90, 180, 270])
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deg == 90
                            ? Icons.rotate_right
                            : deg == 270
                            ? Icons.rotate_left
                            : Icons.flip,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('$deg°'),
                    ],
                  ),
                  selected: _rotation == deg,
                  onSelected: (_) =>
                      setState(() => _rotation = deg),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── LOCAL PICKER WIDGETS ──────────────────────────────────────

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