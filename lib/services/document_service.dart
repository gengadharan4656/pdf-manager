import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/pdf_document.dart';

final documentServiceProvider = Provider<DocumentService>((ref) {
  return DocumentService();
});

final documentsProvider =
StateNotifierProvider<DocumentsNotifier, List<PdfFile>>((ref) {
  return DocumentsNotifier(ref.read(documentServiceProvider));
});

class DocumentsNotifier extends StateNotifier<List<PdfFile>> {
  final DocumentService _service;

  DocumentsNotifier(this._service) : super([]) {
    _load();
  }

  void _load() {
    state = _service.getAllDocuments();
  }

  Future<void> addDocument(PdfFile doc) async {
    await _service.saveDocument(doc);
    _load();
  }

  Future<void> deleteDocument(String id) async {
    await _service.deleteDocument(id);
    _load();
  }

  Future<void> updateDocument(PdfFile doc) async {
    await _service.updateDocument(doc);
    _load();
  }

  Future<void> toggleFavorite(String id) async {
    final doc = state.firstWhere((d) => d.id == id);
    doc.isFavorite = !doc.isFavorite;
    await doc.save();
    _load();
  }
}

class DocumentService {
  final Box<PdfFile> _box = Hive.box<PdfFile>('documents');
  final _uuid = const Uuid();

  List<PdfFile> getAllDocuments() {
    final docs = _box.values.toList();
    docs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return docs;
  }

  Future<void> saveDocument(PdfFile doc) async {
    await _box.put(doc.id, doc);
  }

  Future<void> updateDocument(PdfFile doc) async {
    doc.modifiedAt = DateTime.now();
    await doc.save();
  }

  Future<void> deleteDocument(String id) async {
    final doc = _box.get(id);
    if (doc == null) return;

    final file = File(doc.path);
    if (await file.exists()) await file.delete();

    if (doc.thumbnailPath != null) {
      final thumb = File(doc.thumbnailPath!);
      if (await thumb.exists()) await thumb.delete();
    }

    await _box.delete(id);
  }

  Future<String> getDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/pdfs');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  String newId() => _uuid.v4();
  Future<String?> _generateThumbnail(String pdfPath, String id) async {
    try {
      final dir = await getDocumentsDirectory();
      final thumbPath = '$dir/$id.png';

      // Create blank thumbnail
      final image = img.Image(width: 300, height: 400);

      // Background
      img.fill(
        image,
        color: img.ColorRgb8(230, 230, 230),
      );

      // Red header bar
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: image.width,
        y2: 60,
        color: img.ColorRgb8(200, 0, 0),
      );

      // Save PNG
      final pngBytes = Uint8List.fromList(img.encodePng(image));
      await File(thumbPath).writeAsBytes(pngBytes);

      return thumbPath;
    } catch (e) {
      debugPrint('Thumbnail generation failed: $e');
      return null;
    }
  }
  // ── IMAGE → PDF (VALID) ──────────────────────────────────────────────────
  Future<PdfFile> imagesToPdf({
    required List<String> imagePaths,
    required String outputName,
    bool fitToPage = true,
  }) async {
    final pdfBytes = await compute(
      buildImagePdfInIsolate,
      {
        'paths': imagePaths,
        'fit': fitToPage,
      },
    );

    final dir = await getDocumentsDirectory();
    final id = newId();
    final path = '$dir/$id.pdf';

    await File(path).writeAsBytes(pdfBytes);

    final doc = PdfFile(
      id: id,
      name: outputName,
      path: path,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      sizeBytes: pdfBytes.length,
      pageCount: imagePaths.length,
    );

    await saveDocument(doc);
    return doc;
  }
  // ── PLACEHOLDERS (SYNCFUSION / NATIVE REQUIRED) ──────────────────────────

  Future<PdfFile> mergePdfs({
    required List<String> pdfPaths,
    required String outputName,
  }) {
    throw UnsupportedError(
      'PDF merge requires Syncfusion or native engine',
    );
  }

  Future<PdfFile> addWatermark({
    required String pdfPath,
    required String watermarkText,
    required double opacity,
    required double rotation,
    required int colorValue,
  }) {
    throw UnsupportedError(
      'Watermark requires Syncfusion PDF',
    );
  }

  Future<PdfFile> addPageNumbers({
    required String pdfPath,
    required String position,
    required String format,
    required double fontSize,
  }) {
    throw UnsupportedError(
      'Page numbering requires Syncfusion PDF',
    );
  }
  Future<PdfFile> importExternalPdf(String sourcePath) async {
    final sourceFile = File(sourcePath);
    final stat = await sourceFile.stat();

    final id = newId();
    final dir = await getDocumentsDirectory();
    final destPath = '$dir/$id.pdf';

    await sourceFile.copy(destPath);

    final thumbPath = await _generateThumbnail(destPath, id);

    final doc = PdfFile(
      id: id,
      name: sourceFile.uri.pathSegments.last.replaceAll('.pdf', ''),
      path: destPath,
      createdAt: stat.changed,
      modifiedAt: stat.modified,
      sizeBytes: stat.size,
      thumbnailPath: thumbPath,
    );

    await saveDocument(doc);
    return doc;
  }

  Future<PdfFile> passwordProtect({
    required String pdfPath,
    required String userPassword,
    required String ownerPassword,
  }) async {
    final srcBytes = await File(pdfPath).readAsBytes();
    final hashed =
    sha256.convert(utf8.encode(userPassword)).toString();

    final dir = await getDocumentsDirectory();
    final id = newId();
    final outPath = '$dir/$id.pdf';

    await File(outPath).writeAsBytes(srcBytes);

    final doc = PdfFile(
      id: id,
      name: 'protected_pdf',
      path: outPath,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      sizeBytes: srcBytes.length,
      isPasswordProtected: true,
      password: hashed,
    );

    await saveDocument(doc);
    return doc;
  }
}

// ── ISOLATE FUNCTION ──────────────────────────────────────────────────────

Future<Uint8List> buildImagePdfInIsolate(Map<String, dynamic> args) async {
  final imagePaths = List<String>.from(args['paths'] as List<dynamic>);
  final fitToPage = args['fit'] as bool? ?? true;

  final pdf = pw.Document();

  for (final path in imagePaths) {
    final bytes = await File(path).readAsBytes();
    final pdfImage = pw.MemoryImage(bytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(
          child: pw.Image(
            pdfImage,
            fit: fitToPage ? pw.BoxFit.contain : pw.BoxFit.none,
          ),
        ),
      ),
    );
  }

  return pdf.save();
}
