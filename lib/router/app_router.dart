import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/scanner/crop_screen.dart';
import '../screens/viewer/pdf_viewer_screen.dart';
import '../screens/tools/tools_screen.dart';
import '../screens/tools/merge_pdf_screen.dart';
import '../screens/tools/split_pdf_screen.dart';
import '../screens/tools/compress_pdf_screen.dart';
import '../screens/tools/image_to_pdf_screen.dart';
import '../screens/tools/ocr_screen.dart';
import '../screens/tools/barcode_screen.dart';
import '../screens/tools/watermark_screen.dart';
import '../screens/tools/page_numbers_screen.dart';
import '../screens/tools/password_screen.dart';
import '../screens/tools/rotate_screen.dart';
import '../screens/tools/annotate_screen.dart';
import '../screens/tools/sign_screen.dart';
import '../screens/tools/word_to_pdf_screen.dart';
import '../screens/tools/excel_to_pdf_screen.dart';
import '../screens/tools/html_to_pdf_screen.dart';
import '../screens/tools/grayscale_screen.dart';
import '../screens/tools/delete_pages_screen.dart';
import '../screens/tools/extract_pages_screen.dart';
import '../screens/tools/reorder_screen.dart';
import '../screens/tools/redact_screen.dart';
import '../screens/tools/metadata_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/recent/recent_screen.dart';
import '../models/pdf_document.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text('No route for location: ${state.uri}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/recent', builder: (c, s) => const RecentScreen()),
          GoRoute(path: '/tools', builder: (c, s) => const ToolsScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),
      // Scanner flow
      GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
      GoRoute(
        path: '/crop',
        builder: (c, s) {
          final extra = s.extra as Map<String, dynamic>;
          return CropScreen(imagePath: extra['imagePath'] as String);
        },
      ),
      // Viewer
      GoRoute(
        path: '/viewer',
        builder: (c, s) {
          final doc = s.extra as PdfFile;
          return PdfViewerScreen(document: doc);
        },
      ),
      // Tools
      GoRoute(path: '/tools/merge', builder: (c, s) => const MergePdfScreen()),
      GoRoute(path: '/tools/split', builder: (c, s) => const SplitPdfScreen()),
      GoRoute(
          path: '/tools/compress',
          builder: (c, s) => const CompressPdfScreen()),
      GoRoute(
          path: '/tools/image-to-pdf',
          builder: (c, s) => const ImageToPdfScreen()),
      GoRoute(path: '/tools/ocr', builder: (c, s) => const OcrScreen()),
      GoRoute(
          path: '/tools/barcode', builder: (c, s) => const BarcodeScreen()),
      GoRoute(
          path: '/tools/watermark',
          builder: (c, s) => const WatermarkScreen()),
      GoRoute(
          path: '/tools/page-numbers',
          builder: (c, s) => const PageNumbersScreen()),
      GoRoute(
          path: '/tools/password',
          builder: (c, s) => const PasswordScreen()),
      GoRoute(path: '/tools/rotate', builder: (c, s) => const RotateScreen()),
      GoRoute(
          path: '/tools/annotate',
          builder: (c, s) => const AnnotateScreen()),
      GoRoute(path: '/tools/sign', builder: (c, s) => const SignScreen()),
      GoRoute(
          path: '/tools/word-to-pdf',
          builder: (c, s) => const WordToPdfScreen()),
      GoRoute(
          path: '/tools/excel-to-pdf',
          builder: (c, s) => const ExcelToPdfScreen()),
      GoRoute(
          path: '/tools/html-to-pdf',
          builder: (c, s) => const HtmlToPdfScreen()),
      GoRoute(
          path: '/tools/grayscale',
          builder: (c, s) => const GrayscaleScreen()),
      GoRoute(
          path: '/tools/delete-pages',
          builder: (c, s) => const DeletePagesScreen()),
      GoRoute(
          path: '/tools/extract-pages',
          builder: (c, s) => const ExtractPagesScreen()),
      GoRoute(
          path: '/tools/reorder',
          builder: (c, s) => const ReorderScreen()),
      GoRoute(path: '/tools/redact', builder: (c, s) => const RedactScreen()),
      GoRoute(
          path: '/tools/metadata',
          builder: (c, s) => const MetadataScreen()),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Recent',
    ),
    const NavigationDestination(
      icon: Icon(Icons.build_outlined),
      selectedIcon: Icon(Icons.build),
      label: 'Tools',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  final _routes = ['/', '/recent', '/tools', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          context.go(_routes[i]);
        },
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scanner'),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan'),
        elevation: 4,
      ),
    );
  }
}
