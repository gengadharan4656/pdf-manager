import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/pdf_document.dart';
import '../../services/document_service.dart';
import '../../widgets/pdf_card.dart';
import '../../widgets/search_bar_widget.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.date);
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

enum SortMode { date, name, size }
enum ViewMode { grid, list }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider);
    final query = ref.watch(searchQueryProvider);
    final sortMode = ref.watch(sortModeProvider);
    final viewMode = ref.watch(viewModeProvider);

    final filtered = _filterAndSort(documents, query, sortMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Manager Pro'),
        actions: [
          IconButton(
            icon: Icon(
              viewMode == ViewMode.grid ? Icons.list : Icons.grid_view,
            ),
            onPressed: () {
              ref.read(viewModeProvider.notifier).state =
                  viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
            },
          ),
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (mode) =>
                ref.read(sortModeProvider.notifier).state = mode,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: SortMode.date, child: Text('Sort by Date')),
              PopupMenuItem(
                  value: SortMode.name, child: Text('Sort by Name')),
              PopupMenuItem(
                  value: SortMode.size, child: Text('Sort by Size')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Import PDF',
            onPressed: () => _importPdf(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          SearchBarWidget(
            onChanged: (q) =>
                ref.read(searchQueryProvider.notifier).state = q,
          ),

          // Stats strip
          if (documents.isNotEmpty) _buildStatsStrip(context, documents),

          // Documents grid/list
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context, documents.isEmpty)
                : viewMode == ViewMode.grid
                    ? _buildGrid(context, ref, filtered)
                    : _buildList(context, ref, filtered),
          ),
        ],
      ),
    );
  }

  List<PdfFile> _filterAndSort(
      List<PdfFile> docs, String query, SortMode sort) {
    var filtered = query.isEmpty
        ? docs
        : docs.where((d) =>
            d.name.toLowerCase().contains(query.toLowerCase())).toList();

    switch (sort) {
      case SortMode.date:
        filtered.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        break;
      case SortMode.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.size:
        filtered.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }
    return filtered;
  }

  Widget _buildStatsStrip(BuildContext context, List<PdfFile> docs) {
    final totalSize = docs.fold<int>(0, (sum, d) => sum + d.sizeBytes);
    final favorites = docs.where((d) => d.isFavorite).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '${docs.length}', label: 'Documents'),
          _StatItem(
              value: _formatSize(totalSize), label: 'Total Size'),
          _StatItem(value: '$favorites', label: 'Favorites'),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildGrid(
      BuildContext context, WidgetRef ref, List<PdfFile> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) => PdfCard(
        document: docs[i],
        viewMode: ViewMode.grid,
        onTap: () => context.push('/viewer', extra: docs[i]),
        onMore: () => _showDocumentMenu(context, ref, docs[i]),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<PdfFile> docs) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => PdfCard(
        document: docs[i],
        viewMode: ViewMode.list,
        onTap: () => context.push('/viewer', extra: docs[i]),
        onMore: () => _showDocumentMenu(context, ref, docs[i]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool noDocuments) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noDocuments ? Icons.description_outlined : Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            noDocuments ? 'No PDFs yet' : 'No results found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noDocuments
                ? 'Scan a document or import a PDF to get started'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (noDocuments) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/scanner'),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Document'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && context.mounted) {
      final service = ref.read(documentServiceProvider);
      for (final file in result.files) {
        if (file.path != null) {
          final doc = await service.importExternalPdf(file.path!);
          ref.read(documentsProvider.notifier).addDocument(doc);
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${result.files.length} PDF${result.files.length > 1 ? 's' : ''} imported'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showDocumentMenu(
      BuildContext context, WidgetRef ref, PdfFile doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DocumentMenu(
        document: doc,
        onFavorite: () => ref
            .read(documentsProvider.notifier)
            .toggleFavorite(doc.id),
        onDelete: () async {
          await ref.read(documentsProvider.notifier).deleteDocument(doc.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document deleted')),
            );
          }
        },
        onShare: () => Share.shareXFiles([XFile(doc.path)],
            text: doc.name),
        onRename: () => _showRenameDialog(context, ref, doc),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, PdfFile doc) {
    final ctrl = TextEditingController(text: doc.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = PdfFile(
                id: doc.id,
                name: ctrl.text.trim(),
                path: doc.path,
                createdAt: doc.createdAt,
                modifiedAt: DateTime.now(),
                sizeBytes: doc.sizeBytes,
                pageCount: doc.pageCount,
                tags: doc.tags,
                isFavorite: doc.isFavorite,
                thumbnailPath: doc.thumbnailPath,
                password: doc.password,
                isPasswordProtected: doc.isPasswordProtected,
                openCount: doc.openCount,
                lastOpenedAt: doc.lastOpenedAt,
              );

              await ref
                  .read(documentsProvider.notifier)
                  .updateDocument(updated);

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            )),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _DocumentMenu extends StatelessWidget {
  final PdfFile document;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onRename;

  const _DocumentMenu({
    required this.document,
    required this.onFavorite,
    required this.onDelete,
    required this.onShare,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf,
                    color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                          '${document.sizeFormatted} · ${document.pageCount} pages',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          ...[
            _MenuItem(
              icon: document.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              label: document.isFavorite
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                onFavorite();
              },
            ),
            _MenuItem(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            _MenuItem(
              icon: Icons.edit,
              label: 'Rename',
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            _MenuItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
