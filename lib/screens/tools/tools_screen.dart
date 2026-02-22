import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _searchQuery = '';

  final List<ToolCategory> _categories = [
    ToolCategory(
      name: 'Create & Convert',
      icon: Icons.create_new_folder,
      color: const Color(0xFF1565C0),
      tools: [
        ToolItem('Scan to PDF', Icons.document_scanner, '/scanner',
            'Scan documents with camera', const Color(0xFF1565C0)),
        ToolItem('Image to PDF', Icons.image, '/tools/image-to-pdf',
            'JPG, PNG to PDF', const Color(0xFF1976D2)),
        ToolItem('Word to PDF', Icons.description, '/tools/word-to-pdf',
            'Convert DOCX files', const Color(0xFF1E88E5)),
        ToolItem('Excel to PDF', Icons.table_chart, '/tools/excel-to-pdf',
            'Convert spreadsheets', const Color(0xFF43A047)),
        ToolItem('PPT to PDF', Icons.slideshow, '/tools/word-to-pdf',
            'Convert presentations', const Color(0xFFE53935)),
        ToolItem('HTML to PDF', Icons.web, '/tools/html-to-pdf',
            'Convert web pages', const Color(0xFFFF7043)),
        ToolItem('TXT to PDF', Icons.text_snippet, '/tools/html-to-pdf',
            'Convert text files', const Color(0xFF546E7A)),
        ToolItem('SVG to PDF', Icons.draw, '/tools/image-to-pdf',
            'Vector graphics', const Color(0xFF8E24AA)),
        ToolItem('TIFF to PDF', Icons.photo, '/tools/image-to-pdf',
            'TIFF image conversion', const Color(0xFF00897B)),
      ],
    ),
    ToolCategory(
      name: 'Organize',
      icon: Icons.folder_open,
      color: const Color(0xFF2E7D32),
      tools: [
        ToolItem('Merge PDFs', Icons.merge, '/tools/merge',
            'Combine multiple PDFs', const Color(0xFF2E7D32)),
        ToolItem('Split PDF', Icons.call_split, '/tools/split',
            'Split into separate files', const Color(0xFF388E3C)),
        ToolItem('Reorder Pages', Icons.swap_vert, '/tools/reorder',
            'Drag to reorder pages', const Color(0xFF43A047)),
        ToolItem('Delete Pages', Icons.delete_sweep, '/tools/delete-pages',
            'Remove unwanted pages', const Color(0xFFC62828)),
        ToolItem('Extract Pages', Icons.content_cut, '/tools/extract-pages',
            'Extract specific pages', const Color(0xFF6A1B9A)),
        ToolItem('Rotate PDF', Icons.rotate_right, '/tools/rotate',
            'Rotate pages', const Color(0xFF00838F)),
        ToolItem('Crop PDF', Icons.crop, '/tools/image-to-pdf',
            'Crop page margins', const Color(0xFFF57F17)),
        ToolItem('Resize PDF', Icons.photo_size_select_large,
            '/tools/compress', 'Change page size', const Color(0xFF1565C0)),
      ],
    ),
    ToolCategory(
      name: 'Edit & Enhance',
      icon: Icons.edit,
      color: const Color(0xFFF57F17),
      tools: [
        ToolItem('Annotate PDF', Icons.draw, '/tools/annotate',
            'Add notes & highlights', const Color(0xFFF57F17)),
        ToolItem('eSign PDF', Icons.draw_outlined, '/tools/sign',
            'Add digital signature', const Color(0xFF1565C0)),
        ToolItem('Fill Forms', Icons.edit_note, '/tools/annotate',
            'Fill PDF forms', const Color(0xFF2E7D32)),
        ToolItem('Watermark', Icons.branding_watermark, '/tools/watermark',
            'Add text watermark', const Color(0xFF546E7A)),
        ToolItem('Page Numbers', Icons.format_list_numbered,
            '/tools/page-numbers', 'Add page numbers', const Color(0xFF1976D2)),
        ToolItem('Edit Metadata', Icons.info_outline, '/tools/metadata',
            'Edit title, author', const Color(0xFF6D4C41)),
        ToolItem('Redact PDF', Icons.remove_red_eye_outlined, '/tools/redact',
            'Blackout sensitive info', const Color(0xFF212121)),
        ToolItem('Flatten PDF', Icons.layers_clear, '/tools/compress',
            'Flatten annotations', const Color(0xFF546E7A)),
      ],
    ),
    ToolCategory(
      name: 'Optimize',
      icon: Icons.compress,
      color: const Color(0xFF6A1B9A),
      tools: [
        ToolItem('Compress PDF', Icons.compress, '/tools/compress',
            'Reduce file size', const Color(0xFF6A1B9A)),
        ToolItem('Grayscale PDF', Icons.invert_colors, '/tools/grayscale',
            'Convert to black & white', const Color(0xFF37474F)),
        ToolItem('Hyper-Compress', Icons.compress, '/tools/compress',
            'Maximum compression', const Color(0xFF4A148C)),
        ToolItem('PDF to PDF/A', Icons.verified, '/tools/compress',
            'Archive standard', const Color(0xFF1B5E20)),
        ToolItem('Linearize PDF', Icons.linear_scale, '/tools/compress',
            'Optimize for web', const Color(0xFF0D47A1)),
        ToolItem('Repair PDF', Icons.build, '/tools/compress',
            'Fix corrupt PDFs', const Color(0xFFBF360C)),
      ],
    ),
    ToolCategory(
      name: 'Security',
      icon: Icons.security,
      color: const Color(0xFFC62828),
      tools: [
        ToolItem('Password Protect', Icons.lock, '/tools/password',
            'Encrypt with password', const Color(0xFFC62828)),
        ToolItem('Unlock PDF', Icons.lock_open, '/tools/password',
            'Remove password', const Color(0xFF2E7D32)),
        ToolItem('Redact Content', Icons.hide_source, '/tools/redact',
            'Permanently remove text', const Color(0xFF212121)),
        ToolItem('Remove Content', Icons.delete_forever, '/tools/redact',
            'Remove interactive elements', const Color(0xFF546E7A)),
      ],
    ),
    ToolCategory(
      name: 'Extract & Convert',
      icon: Icons.download,
      color: const Color(0xFF00695C),
      tools: [
        ToolItem('PDF to JPG', Icons.image, '/tools/image-to-pdf',
            'Export as images', const Color(0xFF00695C)),
        ToolItem('PDF to PNG', Icons.image_outlined, '/tools/image-to-pdf',
            'Export as PNG', const Color(0xFF00838F)),
        ToolItem('PDF to Word', Icons.description, '/tools/word-to-pdf',
            'Convert to DOCX', const Color(0xFF1565C0)),
        ToolItem('PDF to Excel', Icons.table_chart, '/tools/excel-to-pdf',
            'Convert to XLSX', const Color(0xFF2E7D32)),
        ToolItem('PDF to PPT', Icons.slideshow, '/tools/word-to-pdf',
            'Convert to PPTX', const Color(0xFFE53935)),
        ToolItem('PDF to Text', Icons.text_fields, '/tools/ocr',
            'Extract text content', const Color(0xFF546E7A)),
        ToolItem('PDF to TIFF', Icons.photo_library, '/tools/image-to-pdf',
            'High quality export', const Color(0xFF6A1B9A)),
        ToolItem('Image to Excel', Icons.table_view, '/tools/ocr',
            'OCR to spreadsheet', const Color(0xFF43A047)),
      ],
    ),
    ToolCategory(
      name: 'AI & Smart Tools',
      icon: Icons.auto_awesome,
      color: const Color(0xFF4527A0),
      tools: [
        ToolItem('OCR PDF', Icons.text_rotation_none, '/tools/ocr',
            'Extract text from scans', const Color(0xFF4527A0)),
        ToolItem('Barcode Reader', Icons.qr_code_scanner, '/tools/barcode',
            'Scan QR & barcodes', const Color(0xFF00695C)),
        ToolItem('Chat with PDF', Icons.chat_bubble_outline, '/tools/ocr',
            'Ask questions about PDF', const Color(0xFF1565C0)),
        ToolItem('Clean Up PDF', Icons.auto_fix_high, '/tools/compress',
            'Remove clutter', const Color(0xFF2E7D32)),
      ],
    ),
    ToolCategory(
      name: 'View & Share',
      icon: Icons.visibility,
      color: const Color(0xFF0277BD),
      tools: [
        ToolItem('PDF Viewer', Icons.picture_as_pdf, '/recent',
            'View documents', const Color(0xFF0277BD)),
        ToolItem('Share PDF', Icons.share, '/recent',
            'Share via apps', const Color(0xFF039BE5)),
        ToolItem('Merge Pages', Icons.view_compact, '/tools/merge',
            'Combine pages on one', const Color(0xFF0288D1)),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _categories
        : _categories
            .map((cat) => ToolCategory(
                  name: cat.name,
                  icon: cat.icon,
                  color: cat.color,
                  tools: cat.tools
                      .where((t) =>
                          t.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          t.subtitle
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList(),
                ))
            .where((cat) => cat.tools.isNotEmpty)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Tools'),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tools...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),

          // Tools list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) =>
                  _CategorySection(category: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ToolCategory category;

  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 20),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: category.color,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: category.tools.length,
          itemBuilder: (_, i) => _ToolTile(tool: category.tools[i]),
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  final ToolItem tool;

  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: tool.color, size: 26),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                tool.name,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<ToolItem> tools;

  ToolCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.tools,
  });
}

class ToolItem {
  final String name;
  final IconData icon;
  final String route;
  final String subtitle;
  final Color color;

  ToolItem(this.name, this.icon, this.route, this.subtitle, this.color);
}
