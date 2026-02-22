import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/pdf_document.dart';
import '../../services/document_service.dart';
import '../../widgets/pdf_card.dart';
import '../../screens/home/home_screen.dart';

class RecentScreen extends ConsumerWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider);

    // Explicitly type this list so analyzer knows lastOpenedAt is non-null
    final List<PdfFile> recent = documents
        .where((d) => d.lastOpenedAt != null)
        .cast<PdfFile>()
        .toList()
      ..sort(
            (a, b) =>
            b.lastOpenedAt!.compareTo(a.lastOpenedAt!),
      );

    final List<PdfFile> favorites =
    documents.where((d) => d.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recent & Favorites')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── FAVORITES ─────────────────────────────────────────────
          if (favorites.isNotEmpty) ...[
            _SectionHeader(
              title: 'Favorites',
              icon: Icons.favorite,
              color: Colors.red,
              count: favorites.length,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                separatorBuilder: (_, __) =>
                const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final doc = favorites[i];
                  return SizedBox(
                    width: 130,
                    child: PdfCard(
                      document: doc,
                      viewMode: ViewMode.grid,
                      onTap: () =>
                          context.push('/viewer', extra: doc),
                      onMore: () {},
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── RECENT ────────────────────────────────────────────────
          _SectionHeader(
            title: 'Recently Opened',
            icon: Icons.history,
            color: Colors.blue,
            count: recent.length,
          ),
          const SizedBox(height: 12),

          if (recent.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recently opened documents',
                      style:
                      TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recent.map((doc) {
              final openedAt = doc.lastOpenedAt!;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                  ),
                  title: Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('MMM d · h:mm a').format(openedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () {
                      Share.shareXFiles(
                        [XFile(doc.path)],
                      );
                    },
                  ),
                  onTap: () =>
                      context.push('/viewer', extra: doc),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const Spacer(),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}