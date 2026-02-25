import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

import '../../models/pdf_document.dart';
import '../../services/document_service.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final PdfFile document;

  const PdfViewerScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();

  bool _showToolbar = true;
  bool _isSearching = false;
  late final bool _fileExists;

  int _currentPage = 1;
  int _pageCount = 1;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fileExists = File(widget.document.path).existsSync();
    if (_fileExists) {
      _incrementOpenCount();
    }
  }

  void _incrementOpenCount() {
    final doc = widget.document;
    doc.openCount++;
    doc.lastOpenedAt = DateTime.now();
    ref.read(documentsProvider.notifier).updateDocument(doc);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: _showToolbar ? _buildAppBar(context) : null,
      body: _fileExists
          ? GestureDetector(
              onTap: () => setState(() => _showToolbar = !_showToolbar),
              child: PdfViewer.file(
                widget.document.path,
                controller: _controller,
                params: PdfViewerParams(
                  backgroundColor: Colors.grey.shade900,
                  margin: 8,
                  maxScale: 8.0,
                  minScale: 0.5,
                  pageDropShadow: const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                  onViewerReady: (doc, controller) {
                    setState(() {
                      _pageCount = doc.pages.length;
                    });

                    if (widget.document.pageCount != _pageCount) {
                      widget.document.pageCount = _pageCount;
                      ref
                          .read(documentsProvider.notifier)
                          .updateDocument(widget.document);
                    }
                  },
                  onPageChanged: (page) {
                    if (page != null) {
                      setState(() => _currentPage = page);
                    }
                  },
                ),
              ),
            )
          : _buildFileMissingView(context),
      bottomNavigationBar: _showToolbar && _fileExists ? _buildBottomBar() : null,
    );
  }

  Widget _buildFileMissingView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 56),
            const SizedBox(height: 12),
            const Text(
              'File not found on device',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.document.path,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await OpenFile.open(widget.document.path);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Try Open Externally'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.grey.shade900,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search in document...',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      )
          : Text(
        widget.document.name,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => Share.shareXFiles(
            [XFile(widget.document.path)],
            text: widget.document.name,
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'annotate', child: Text('Annotate')),
            PopupMenuItem(value: 'sign', child: Text('Sign')),
            PopupMenuItem(value: 'watermark', child: Text('Watermark')),
            PopupMenuItem(value: 'page-numbers', child: Text('Add Page Numbers')),
            PopupMenuItem(value: 'compress', child: Text('Compress')),
            PopupMenuItem(value: 'rotate', child: Text('Rotate Pages')),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ViewerButton(
            icon: Icons.chevron_left,
            label: 'Prev',
            onTap: () {
              if (_currentPage > 1) {
                _controller.goToPage(pageNumber: _currentPage - 1);
              }
            },
          ),
          _ViewerButton(
            icon: Icons.first_page,
            label: 'First',
            onTap: () => _controller.goToPage(pageNumber: 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_currentPage / $_pageCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ViewerButton(
            icon: Icons.last_page,
            label: 'Last',
            onTap: () => _controller.goToPage(pageNumber: _pageCount),
          ),
          _ViewerButton(
            icon: Icons.chevron_right,
            label: 'Next',
            onTap: () {
              if (_currentPage < _pageCount) {
                _controller.goToPage(pageNumber: _currentPage + 1);
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final routes = {
      'annotate': '/tools/annotate',
      'sign': '/tools/sign',
      'watermark': '/tools/watermark',
      'page-numbers': '/tools/page-numbers',
      'compress': '/tools/compress',
      'rotate': '/tools/rotate',
    };

    final route = routes[action];
    if (route != null) context.push(route);
  }
}

class _ViewerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ViewerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }
}