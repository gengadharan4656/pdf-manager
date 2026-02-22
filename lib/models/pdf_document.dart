import 'package:hive/hive.dart';

part 'pdf_document.g.dart';

@HiveType(typeId: 0)
class PdfFile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime modifiedAt;

  @HiveField(5)
  final int sizeBytes;

  @HiveField(6)
  int pageCount;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  bool isFavorite;

  @HiveField(9)
  String? thumbnailPath;

  @HiveField(10)
  String? password;

  @HiveField(11)
  bool isPasswordProtected;

  @HiveField(12)
  int openCount;

  @HiveField(13)
  DateTime? lastOpenedAt;

  PdfFile({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.modifiedAt,
    required this.sizeBytes,
    this.pageCount = 0,
    this.tags = const [],
    this.isFavorite = false,
    this.thumbnailPath,
    this.password,
    this.isPasswordProtected = false,
    this.openCount = 0,
    this.lastOpenedAt,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

@HiveType(typeId: 1)
class PdfTag extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int colorValue;

  PdfTag({
    required this.name,
    required this.colorValue,
  });
}