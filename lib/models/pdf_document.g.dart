// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfFileAdapter extends TypeAdapter<PdfFile> {
  @override
  final int typeId = 0;

  @override
  PdfFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfFile(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      createdAt: fields[3] as DateTime,
      modifiedAt: fields[4] as DateTime,
      sizeBytes: fields[5] as int,
      pageCount: fields[6] as int,
      tags: (fields[7] as List).cast<String>(),
      isFavorite: fields[8] as bool,
      thumbnailPath: fields[9] as String?,
      password: fields[10] as String?,
      isPasswordProtected: fields[11] as bool,
      openCount: fields[12] as int,
      lastOpenedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PdfFile obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.modifiedAt)
      ..writeByte(5)
      ..write(obj.sizeBytes)
      ..writeByte(6)
      ..write(obj.pageCount)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.isFavorite)
      ..writeByte(9)
      ..write(obj.thumbnailPath)
      ..writeByte(10)
      ..write(obj.password)
      ..writeByte(11)
      ..write(obj.isPasswordProtected)
      ..writeByte(12)
      ..write(obj.openCount)
      ..writeByte(13)
      ..write(obj.lastOpenedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PdfTagAdapter extends TypeAdapter<PdfTag> {
  @override
  final int typeId = 1;

  @override
  PdfTag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfTag(
      name: fields[0] as String,
      colorValue: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PdfTag obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfTagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
