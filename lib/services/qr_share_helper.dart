/// Enhanced QR sharing with compression and P2P fallback
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// QR Data types
enum QRDataType {
  inline, // Small data embedded directly in QR
  p2p, // Large files shared via P2P
}

/// QR Payload structure
class QRPayload {
  final QRDataType type;
  final Map<String, dynamic> data;

  QRPayload({required this.type, required this.data});

  String toJson() => jsonEncode({
        'v': 2, // Version 2 with compression support
        'type': type.name,
        'data': data,
      });

  factory QRPayload.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final typeStr = map['type'] as String;
    final type = QRDataType.values.firstWhere((e) => e.name == typeStr);

    return QRPayload(
      type: type,
      data: map['data'] as Map<String, dynamic>,
    );
  }
}

/// QR Share Helper - Smart compression and P2P fallback
class QRShareHelper {
  // Maximum QR code capacity (approximately 2953 bytes for alphanumeric)
  // We use 2000 bytes to be safe
  static const int maxQRSize = 2000;

  // Maximum size for compression attempt (5MB)
  static const int maxCompressionSize = 5 * 1024 * 1024;

  /// Prepare content for QR sharing
  /// Returns QRPayload with either inline data or P2P info
  static Future<QRPayload> prepareForSharing({
    required String title,
    required String content,
    String? filePath,
    String fileType = 'text',
    String? classId,
    String? subjectId,
    String? categoryId,
  }) async {
    // Case 1: Plain text content (AI generated notes)
    if (filePath == null || filePath.isEmpty) {
      return await _prepareTextContent(title, content,
          classId: classId, subjectId: subjectId, categoryId: categoryId);
    }

    // Case 2: File-based content (PDF, images)
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    return await _prepareFileContent(file, title, fileType,
        classId: classId, subjectId: subjectId, categoryId: categoryId);
  }

  /// Prepare text content (AI notes)
  static Future<QRPayload> _prepareTextContent(String title, String content,
      {String? classId, String? subjectId, String? categoryId}) async {
    try {
      final textBytes = utf8.encode(content);
      debugPrint('📝 Preparing text content: ${textBytes.length} bytes');

      // Compress text using gzip
      final compressed = GZipEncoder().encode(textBytes);

      if (compressed.isEmpty) {
        // Compression failed, check if we need P2P
        if (textBytes.length > maxQRSize) {
          debugPrint('🚀 Text too large, switching to P2P mode');
          return await _createTextP2PPayload(title, content, textBytes.length,
              classId: classId, subjectId: subjectId, categoryId: categoryId);
        }
        return _createInlinePayload(title, content, 'text', false,
            classId: classId, subjectId: subjectId, categoryId: categoryId);
      }

      // Check if compressed size fits in QR
      final compressedBase64 = base64Encode(compressed);
      final payload = {
        'title': title,
        'content': compressedBase64,
        'type': 'text',
        'compressed': true,
        if (classId != null) 'classId': classId,
        if (subjectId != null) 'subjectId': subjectId,
        if (categoryId != null) 'categoryId': categoryId,
      };

      final jsonStr = jsonEncode(payload);

      if (jsonStr.length <= maxQRSize) {
        debugPrint(
            '✓ Text compressed: ${textBytes.length}b → ${compressed.length}b');
        return QRPayload(type: QRDataType.inline, data: payload);
      }

      // Still too large after compression, use P2P mode
      debugPrint(
          '🚀 Text too large even compressed (${jsonStr.length}b > $maxQRSize), switching to P2P mode');
      return await _createTextP2PPayload(title, content, textBytes.length,
          classId: classId, subjectId: subjectId, categoryId: categoryId);
    } catch (e) {
      debugPrint('Text preparation error: $e');
      // Fallback to P2P on any error
      return await _createTextP2PPayload(title, content, content.length,
          classId: classId, subjectId: subjectId, categoryId: categoryId);
    }
  }

  /// Prepare file content (PDF, images) - AirDrop-like smart sharing
  static Future<QRPayload> _prepareFileContent(
      File file, String title, String fileType,
      {String? classId, String? subjectId, String? categoryId}) async {
    try {
      final fileSize = await file.length();
      debugPrint(
          '📦 Analyzing file: ${p.basename(file.path)} (${_formatBytes(fileSize)})');

      // Try aggressive compression with multiple quality levels
      final compressionResult = await _tryMultiLevelCompression(file, fileSize);

      if (compressionResult != null) {
        final base64Content = base64Encode(compressionResult);
        final payload = {
          'title': title,
          'content': base64Content,
          'type': fileType,
          'fileName': p.basename(file.path),
          'fileSize': fileSize,
          'compressed': true,
          if (classId != null) 'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
          if (categoryId != null) 'categoryId': categoryId,
        };

        final jsonStr = jsonEncode(payload);
        if (jsonStr.length <= maxQRSize) {
          debugPrint(
              '✓ Compressed to fit QR: ${fileSize} → ${compressionResult.length} bytes');
          return QRPayload(type: QRDataType.inline, data: payload);
        }

        debugPrint(
            '⚠ Still too large after compression (${jsonStr.length}b > $maxQRSize)');
      }

      // Automatic P2P fallback - NO truncation!
      debugPrint('🚀 Switching to P2P mode (AirDrop-like transfer)');
      return _createP2PPayload(file, title, fileType, fileSize,
          classId: classId, subjectId: subjectId, categoryId: categoryId);
    } catch (e) {
      debugPrint('File preparation error: $e');
      rethrow;
    }
  }

  /// Try multi-level compression with different strategies
  static Future<Uint8List?> _tryMultiLevelCompression(
      File file, int originalSize) async {
    try {
      final bytes = await file.readAsBytes();

      // Level 1: Standard gzip (fast, decent ratio)
      debugPrint('🔄 Level 1: Gzip compression...');
      var compressed = GZipEncoder().encode(bytes);
      final result1 = Uint8List.fromList(compressed);
      if (result1.length < 1500) {
        debugPrint(
            '✓ Success: ${originalSize} → ${result1.length} bytes (${((1 - result1.length / originalSize) * 100).toStringAsFixed(1)}% reduction)');
        return result1;
      }
      debugPrint('  → ${result1.length} bytes (still too large)');

      // Level 2: ZLib with maximum compression
      debugPrint('🔄 Level 2: ZLib max compression...');
      final deflated = ZLibEncoder().encode(bytes);
      final result2 = Uint8List.fromList(deflated);
      if (result2.length < 1500) {
        debugPrint(
            '✓ Success: ${originalSize} → ${result2.length} bytes (${((1 - result2.length / originalSize) * 100).toStringAsFixed(1)}% reduction)');
        return result2;
      }
      debugPrint('  → ${result2.length} bytes (still too large)');

      // Level 3: BZip2 (slowest but best ratio)
      debugPrint('🔄 Level 3: BZip2 compression...');
      try {
        final bz2 = BZip2Encoder().encode(bytes);
        final result3 = Uint8List.fromList(bz2);
        if (result3.length < 1500) {
          debugPrint(
              '✓ Success: ${originalSize} → ${result3.length} bytes (${((1 - result3.length / originalSize) * 100).toStringAsFixed(1)}% reduction)');
          return result3;
        }
        debugPrint('  → ${result3.length} bytes (still too large)');
      } catch (e) {
        debugPrint('  ⚠ BZip2 failed: $e');
      }

      debugPrint('✗ All compression attempts exceeded QR size limit');
      return null;
    } catch (e) {
      debugPrint('✗ Compression error: $e');
      return null;
    }
  }

  /// Format bytes for human-readable display
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Create inline payload
  static QRPayload _createInlinePayload(
      String title, String content, String type, bool compressed,
      {String? classId, String? subjectId, String? categoryId}) {
    return QRPayload(
      type: QRDataType.inline,
      data: {
        'title': title,
        'content': content,
        'type': type,
        'compressed': compressed,
        if (classId != null) 'classId': classId,
        if (subjectId != null) 'subjectId': subjectId,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );
  }

  /// Create P2P payload (placeholder for file path)
  static QRPayload _createP2PPayload(
      File file, String title, String fileType, int fileSize,
      {String? classId, String? subjectId, String? categoryId}) {
    return QRPayload(
      type: QRDataType.p2p,
      data: {
        'title': title,
        'fileName': p.basename(file.path),
        'fileType': fileType,
        'fileSize': fileSize,
        'filePath': file.path, // Will be replaced with P2P session info
        if (classId != null) 'classId': classId,
        if (subjectId != null) 'subjectId': subjectId,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );
  }

  /// Create P2P payload for text content (save to temp file first)
  static Future<QRPayload> _createTextP2PPayload(
      String title, String content, int contentSize,
      {String? classId, String? subjectId, String? categoryId}) async {
    try {
      // Save text to temporary file for P2P transfer
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final tempFile =
          File('${tempDir.path}/note_${sanitizedTitle}_$timestamp.txt');

      await tempFile.writeAsString(content);
      debugPrint(
          '📄 Saved text to temp file: ${tempFile.path} (${_formatBytes(contentSize)})');

      return QRPayload(
        type: QRDataType.p2p,
        data: {
          'title': title,
          'fileName': '${sanitizedTitle}.txt',
          'fileType': 'text',
          'fileSize': contentSize,
          'filePath': tempFile.path, // Temp file for P2P transfer
          if (classId != null) 'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
    } catch (e) {
      debugPrint('Error creating text P2P payload: $e');
      rethrow;
    }
  }

  /// Decode received QR content
  static Future<Map<String, dynamic>> decodeQRContent(String qrData) async {
    try {
      final payload = QRPayload.fromJson(qrData);

      if (payload.type == QRDataType.inline) {
        return await _decodeInlineContent(payload.data);
      } else if (payload.type == QRDataType.p2p) {
        return await _decodeP2PContent(payload.data);
      }

      throw Exception('Unknown QR data type');
    } catch (e) {
      debugPrint('QR decode error: $e');

      // Fallback: Try old format
      try {
        final decoded = jsonDecode(qrData) as Map<String, dynamic>;
        return decoded;
      } catch (_) {
        throw Exception('Invalid QR code format');
      }
    }
  }

  /// Decode inline content
  static Future<Map<String, dynamic>> _decodeInlineContent(
      Map<String, dynamic> data) async {
    final compressed = data['compressed'] as bool? ?? false;

    if (compressed) {
      final type = data['type'] as String;

      if (type == 'text') {
        // Decompress text
        final compressedBase64 = data['content'] as String;
        final compressedBytes = base64Decode(compressedBase64);
        final decompressed = GZipDecoder().decodeBytes(compressedBytes);
        final text = utf8.decode(decompressed);

        return {
          'title': data['title'],
          'content': text,
          'type': 'text',
        };
      } else {
        // Decompress file
        final compressedBase64 = data['content'] as String;
        final compressedBytes = base64Decode(compressedBase64);
        final decompressed = GZipDecoder().decodeBytes(compressedBytes);

        return {
          'title': data['title'],
          'fileBytes': Uint8List.fromList(decompressed),
          'fileName': data['fileName'],
          'fileSize': data['fileSize'],
          'type': data['type'],
        };
      }
    }

    // Not compressed
    if (data['type'] == 'text') {
      return {
        'title': data['title'],
        'content': data['content'],
        'type': 'text',
      };
    } else {
      // File embedded
      final base64Content = data['content'] as String;
      final fileBytes = base64Decode(base64Content);

      return {
        'title': data['title'],
        'fileBytes': Uint8List.fromList(fileBytes),
        'fileName': data['fileName'],
        'fileSize': data['fileSize'],
        'type': data['type'],
      };
    }
  }

  /// Decode P2P content (returns P2P session info)
  static Future<Map<String, dynamic>> _decodeP2PContent(
      Map<String, dynamic> data) async {
    return {
      'type': 'p2p',
      'title': data['title'],
      'fileName': data['fileName'],
      'fileType': data['fileType'],
      'fileSize': data['fileSize'],
      'sessionInfo': data, // P2P session details
    };
  }

  /// Get size estimate for QR capacity
  static int estimateQRSize(Map<String, dynamic> data) {
    try {
      final jsonStr = jsonEncode(data);
      return jsonStr.length;
    } catch (_) {
      return 0;
    }
  }
}
