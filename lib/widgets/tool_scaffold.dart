import 'package:flutter/material.dart';

class ToolScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final Widget child;
  final bool isProcessing;
  final String actionLabel;
  final VoidCallback? onAction;

  const ToolScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.child,
    this.isProcessing = false,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),

          // Processing overlay
          if (isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('This may take a moment'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: isProcessing ? null : onAction,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
            ),
            child: isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(actionLabel,
                    style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _EmptyFilePicker extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptyFilePicker({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.04),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file,
                  color: Theme.of(context).colorScheme.primary, size: 36),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500)),
              Text('Tap to select files',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
