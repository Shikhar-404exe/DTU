import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:archive/archive.dart';

import '../main.dart';
import '../models/note_organization.dart';
import '../services/storage_service.dart';
import '../services/p2p_file_share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteScanQR extends StatefulWidget {
  const NoteScanQR({super.key});

  @override
  State<NoteScanQR> createState() => _NoteScanQRState();
}

class _NoteScanQRState extends State<NoteScanQR> {
  bool _isDecoding = false;
  String? _error;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveAsOrganizedNote({
    required String title,
    required String type,
    String? content,
    String? filePath,
    String? classId,
    String? subjectId,
    String? categoryId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userClassId =
          classId ?? prefs.getString('profile_class_id') ?? 'class_10';

      String finalCategoryId = categoryId ?? 'other';
      if (finalCategoryId == 'other') {
        if (type == 'pdf' || type == 'ebook') {
          finalCategoryId = 'scanned';
        } else if (type == 'text') {
          finalCategoryId = 'notes';
        }
      }

      String finalSubjectId = subjectId ?? 'other';
      if (finalSubjectId == 'other') {
        final titleLower = title.toLowerCase();

        if (titleLower.contains('math') || titleLower.contains('गणित')) {
          finalSubjectId = 'math';
        } else if (titleLower.contains('science') ||
            titleLower.contains('विज्ञान')) {
          finalSubjectId = 'science';
        } else if (titleLower.contains('english') ||
            titleLower.contains('अंग्रेजी')) {
          finalSubjectId = 'english';
        } else if (titleLower.contains('hindi') ||
            titleLower.contains('हिंदी')) {
          finalSubjectId = 'hindi';
        } else if (titleLower.contains('physics') ||
            titleLower.contains('भौतिकी')) {
          finalSubjectId = 'physics';
        } else if (titleLower.contains('chemistry') ||
            titleLower.contains('रसायन')) {
          finalSubjectId = 'chemistry';
        } else if (titleLower.contains('biology') ||
            titleLower.contains('जीव')) {
          finalSubjectId = 'biology';
        } else if (titleLower.contains('history') ||
            titleLower.contains('इतिहास')) {
          finalSubjectId = 'history';
        } else if (titleLower.contains('geography') ||
            titleLower.contains('भूगोल')) {
          finalSubjectId = 'geography';
        } else if (titleLower.contains('computer')) {
          finalSubjectId = 'computer';
        }
      }

      final newNote = OrganizedNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content ?? 'Downloaded note',
        classId: userClassId,
        subjectId: finalSubjectId,
        categoryId: finalCategoryId,
        createdAt: DateTime.now(),
        filePath: filePath,
        type: type,
      );

      final notesJson = prefs.getString('organized_notes') ?? '[]';
      final notesList =
          (jsonDecode(notesJson) as List).cast<Map<String, dynamic>>();
      notesList.add(newNote.toJson());
      await prefs.setString('organized_notes', jsonEncode(notesList));
    } catch (e) {
      debugPrint('Failed to save as organized note: $e');
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isDecoding) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final barcode = barcodes.first;

    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() {
      _isDecoding = true;
      _error = null;
    });

    try {

      try {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        if (payload['v'] == 2) {
          await _handleV2Payload(payload);
          return;
        }
      } catch (_) {

      }

      if (raw.startsWith("NDP2P1|")) {
        await _handleP2PFileQr(raw);
      } else if (raw.startsWith("NDQR1|") || raw.startsWith("NDQR2|")) {
        await _handleNoteQr(raw);
      } else {
        throw "Unknown QR format. Please use the latest app version.";
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reading QR: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDecoding = false;
        });
      }
    }
  }

  Future<void> _handleV2Payload(Map<String, dynamic> payload) async {
    final type = payload['type'] as String?;
    final data = payload['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw "Invalid v2 payload: missing data";
    }

    if (type == 'inline') {
      await _handleV2Inline(data);
    } else if (type == 'p2p') {
      await _handleV2P2P(data);
    } else {
      throw "Unknown v2 payload type: $type";
    }
  }

  Future<void> _handleV2Inline(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Scanned Note';
    final contentB64 = data['content'] as String?;
    final type = data['type'] as String? ?? 'text';
    final compressed = data['compressed'] == true;
    final fileName = data['fileName'] as String?;

    final classId = data['classId'] as String?;
    final subjectId = data['subjectId'] as String?;
    final categoryId = data['categoryId'] as String?;

    if (contentB64 == null) {
      throw "Missing content in inline payload";
    }

    String content;
    List<int>? fileBytes;

    if (compressed) {

      try {
        final compressedBytes = base64Decode(contentB64);
        final decompressed = GZipDecoder().decodeBytes(compressedBytes);

        if (type == 'text') {
          content = utf8.decode(decompressed);
        } else {

          fileBytes = decompressed;
          content = 'File content';
        }
      } catch (e) {
        throw "Failed to decompress content: $e";
      }
    } else {

      if (type == 'text') {
        try {
          content = utf8.decode(base64Decode(contentB64));
        } catch (_) {
          content = contentB64;
        }
      } else {

        fileBytes = base64Decode(contentB64);
        content = 'File content';
      }
    }

    String? filePath;
    if (type != 'text' && fileBytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      final extension = type == 'pdf' ? 'pdf' : 'dat';
      final safeFileName = fileName ??
          'file_${DateTime.now().millisecondsSinceEpoch}.$extension';
      filePath = p.join(dir.path, safeFileName);
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    } else if (type == 'text') {

      final dir = await getApplicationDocumentsDirectory();
      filePath =
          p.join(dir.path, 'text_${DateTime.now().millisecondsSinceEpoch}.txt');
      final file = File(filePath);
      await file.writeAsString(content);
    }

    final notes = await StorageService.loadNotes();
    notes.add({
      "title": title,
      "timestamp": DateTime.now().toIso8601String(),
      "type": type == 'pdf' ? 'pdf' : 'text',
      "content": type == 'text' ? content : '',
      if (filePath != null) "filePath": filePath,
    });
    await StorageService.saveNotes(notes);

    await _saveAsOrganizedNote(
      title: title,
      type: type == 'pdf' ? 'pdf' : 'text',
      content: type == 'text' ? content : null,
      filePath: filePath,
      classId: classId,
      subjectId: subjectId,
      categoryId: categoryId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $title received successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    if (type == 'text') {
      _showNotePreview(title, content);
    }
  }

  Future<void> _handleV2P2P(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Received File';
    final ip = data['ip'] as String?;
    final port = data['port'];
    final sessionId = data['sessionId'] as String?;
    final fileName = data['fileName'] as String? ?? 'file.pdf';
    final fileType = data['type'] as String? ?? 'pdf';
    final networkName = data['networkName'] as String?;

    final classId = data['classId'] as String?;
    final subjectId = data['subjectId'] as String?;
    final categoryId = data['categoryId'] as String?;

    if (ip == null || sessionId == null || port == null) {
      throw "Incomplete P2P data (missing IP/port/sessionId)";
    }

    final intPort = port is int ? port : int.tryParse(port.toString());
    if (intPort == null) {
      throw "Invalid port in P2P data";
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.salmon),
            const SizedBox(height: 16),
            Text('Downloading from $ip...'),
            if (networkName != null)
              Text(
                'Network: $networkName',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );

    try {

      final file = await P2PFileShareService.downloadFile(
        ip: ip,
        port: intPort,
        sessionId: sessionId,
        suggestedName: fileName,
      );

      String? textContent;
      String noteType;

      if (fileType == 'text') {

        textContent = await file.readAsString();
        noteType = 'text';
      } else if (fileType == 'pdf' || fileType == 'ebook') {
        noteType = 'pdf';
      } else {
        noteType = 'file';
      }

      final notes = await StorageService.loadNotes();
      notes.add({
        "title": title,
        "timestamp": DateTime.now().toIso8601String(),
        "type": noteType,
        "filePath": file.path,
        if (textContent != null) "content": textContent,
      });
      await StorageService.saveNotes(notes);

      await _saveAsOrganizedNote(
        title: title,
        type: noteType,
        content: textContent,
        filePath: file.path,
        classId: classId,
        subjectId: subjectId,
        categoryId: categoryId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ $title received successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      throw "P2P download failed: $e";
    }
  }

  void _showNotePreview(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(title),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNoteQr(String raw) async {
    final parts = raw.split("|");
    if (parts.length < 2) {
      throw "Corrupted QR data";
    }
    final chunk = parts.last;

    final compressedBytes = base64Decode(chunk);

    String payloadText;
    try {
      payloadText = utf8.decode(compressedBytes);
    } catch (_) {
      try {
        final d1 = zlib.decode(compressedBytes);
        payloadText = utf8.decode(d1);
      } catch (_) {
        List<int> data = compressedBytes;
        for (int i = 0; i < 3; i++) {
          data = zlib.decode(data);
        }
        payloadText = utf8.decode(data);
      }
    }

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(payloadText);
      if (decoded is Map) {
        payload = decoded.cast<String, dynamic>();
      }
    } catch (_) {
      payload = null;
    }

    String displayTitle = "Scanned Note";
    String? displayText;

    final notes = await StorageService.loadNotes();
    final timestamp = DateTime.now().toIso8601String();

    if (payload != null && payload.containsKey("type")) {
      final type = payload["type"] as String? ?? "text";
      final title = payload["title"] as String? ?? "Scanned Note";

      if (type == "text") {
        final content = payload["content"] as String? ?? payloadText;

        final classId = payload["classId"] as String?;
        final subjectId = payload["subjectId"] as String?;
        final categoryId = payload["categoryId"] as String?;

        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(
            dir.path, "qr_text_${DateTime.now().millisecondsSinceEpoch}.txt");
        final textFile = File(filePath);
        await textFile.writeAsString(content);

        notes.add({
          "title": title,
          "timestamp": timestamp,
          "type": "text",
          "content": content,
        });
        await StorageService.saveNotes(notes);

        await _saveAsOrganizedNote(
          title: title,
          type: "text",
          content: content,
          filePath: filePath,
          classId: classId,
          subjectId: subjectId,
          categoryId: categoryId,
        );

        displayTitle = title;
        displayText = content;
      } else if (type == "pdf") {
        final pdfB64 = payload["pdfBase64"] as String?;
        if (pdfB64 == null) {
          throw "PDF data missing in QR payload";
        }
        final bytes = base64Decode(pdfB64);
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(
            dir.path, "qr_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf");
        final pdfFile = File(filePath);
        await pdfFile.writeAsBytes(bytes);

        final classId = payload["classId"] as String?;
        final subjectId = payload["subjectId"] as String?;
        final categoryId = payload["categoryId"] as String?;

        notes.add({
          "title": title,
          "timestamp": timestamp,
          "type": "pdf",
          "filePath": filePath,
        });
        await StorageService.saveNotes(notes);

        await _saveAsOrganizedNote(
          title: title,
          type: "pdf",
          filePath: filePath,
          classId: classId,
          subjectId: subjectId,
          categoryId: categoryId,
        );

        displayTitle = title;
        displayText = "PDF note imported.\nOpen it from Saved Notes screen.";
      } else if (type == "image") {
        final imgB64 = payload["imageBase64"] as String?;
        if (imgB64 == null) {
          throw "Image data missing in QR payload";
        }
        final bytes = base64Decode(imgB64);
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(
            dir.path, "qr_img_${DateTime.now().millisecondsSinceEpoch}.jpg");
        final imgFile = File(filePath);
        await imgFile.writeAsBytes(bytes);

        final classId = payload["classId"] as String?;
        final subjectId = payload["subjectId"] as String?;
        final categoryId = payload["categoryId"] as String?;

        notes.add({
          "title": title,
          "timestamp": timestamp,
          "type": "image",
          "filePath": filePath,
        });
        await StorageService.saveNotes(notes);

        await _saveAsOrganizedNote(
          title: title,
          type: "image",
          filePath: filePath,
          classId: classId,
          subjectId: subjectId,
          categoryId: categoryId,
        );

        displayTitle = title;
        displayText = "Image note saved. View it in Saved Notes.";
      } else {

        final content = payload["content"] as String? ?? payloadText;

        final classId = payload["classId"] as String?;
        final subjectId = payload["subjectId"] as String?;
        final categoryId = payload["categoryId"] as String?;

        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(
            dir.path, "qr_text_${DateTime.now().millisecondsSinceEpoch}.txt");
        final textFile = File(filePath);
        await textFile.writeAsString(content);

        notes.add({
          "title": title,
          "timestamp": timestamp,
          "type": "text",
          "content": content,
        });
        await StorageService.saveNotes(notes);

        await _saveAsOrganizedNote(
          title: title,
          type: "text",
          content: content,
          filePath: filePath,
          classId: classId,
          subjectId: subjectId,
          categoryId: categoryId,
        );

        displayTitle = title;
        displayText = content;
      }
    } else {

      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(
          dir.path, "qr_text_${DateTime.now().millisecondsSinceEpoch}.txt");
      final textFile = File(filePath);
      await textFile.writeAsString(payloadText);

      notes.add({
        "title": displayTitle,
        "timestamp": timestamp,
        "type": "text",
        "content": payloadText,
      });
      await StorageService.saveNotes(notes);

      await _saveAsOrganizedNote(
        title: displayTitle,
        type: "text",
        content: payloadText,
        filePath: filePath,
      );

      displayText = payloadText;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(displayTitle)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                displayText ?? "",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleP2PFileQr(String raw) async {

    final parts = raw.split("|");
    if (parts.length < 2) throw "Corrupted P2P QR data";

    final b64 = parts[1];
    final jsonText = utf8.decode(base64Decode(b64));
    final map = jsonDecode(jsonText);
    if (map is! Map) throw "Invalid P2P payload";

    final payload = map.cast<String, dynamic>();

    if (payload["kind"] != "p2p_file") {
      throw "Unsupported P2P QR kind";
    }

    final ip = payload["ip"] as String?;
    final port = payload["port"];
    final sessionId = payload["sessionId"] as String?;
    final fileName = payload["fileName"] as String? ?? "file.pdf";
    final fileType = payload["fileType"] as String? ?? "pdf";
    final title = payload["title"] as String? ?? "Received File";

    final classId = payload["classId"] as String?;
    final subjectId = payload["subjectId"] as String?;
    final categoryId = payload["categoryId"] as String?;

    if (ip == null || sessionId == null || port == null) {
      throw "Incomplete P2P data (missing IP/port/sessionId)";
    }

    final intPort = port is int ? port : int.tryParse(port.toString());
    if (intPort == null) {
      throw "Invalid port in P2P data";
    }

    final file = await P2PFileShareService.downloadFile(
      ip: ip,
      port: intPort,
      sessionId: sessionId,
      suggestedName: fileName,
    );

    final notes = await StorageService.loadNotes();
    final timestamp = DateTime.now().toIso8601String();

    final type = (fileType == "ebook" || fileType == "pdf") ? "pdf" : "file";

    notes.add({
      "title": title,
      "timestamp": timestamp,
      "type": type,
      "filePath": file.path,
    });
    await StorageService.saveNotes(notes);

    await _saveAsOrganizedNote(
      title: title,
      type: type,
      filePath: file.path,
      classId: classId,
      subjectId: subjectId,
      categoryId: categoryId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✓ $title received successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final scanAreaSize = screenSize.width * 0.7;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Scan QR Code",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.black87),
          elevation: 0,
        ),
        body: Column(
          children: [

            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [

                      MobileScanner(
                        onDetect: _onDetect,
                      ),

                      Center(
                        child: Container(
                          width: scanAreaSize,
                          height: scanAreaSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.salmonDark
                                  : AppColors.salmon,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [

                              Positioned(
                                top: 0,
                                left: 0,
                                child: _buildCorner(isDark, topLeft: true),
                              ),

                              Positioned(
                                top: 0,
                                right: 0,
                                child: _buildCorner(isDark, topRight: true),
                              ),

                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: _buildCorner(isDark, bottomLeft: true),
                              ),

                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: _buildCorner(isDark, bottomRight: true),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  Colors.black.withAlpha(153),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Align QR code within the frame",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_error != null)
                        Positioned(
                          bottom: 60,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(230),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Scan a note QR to import shared notes",
                style: TextStyle(
                  color: isDark ? AppColors.textLightDark : Colors.black54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(
    bool isDark, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    final color = isDark ? AppColors.salmonDark : AppColors.salmon;
    const size = 30.0;
    const thickness = 4.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: thickness,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.color,
    required this.thickness,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (topLeft) {
      path.moveTo(0, size.height * 0.6);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.6, 0);
    } else if (topRight) {
      path.moveTo(size.width * 0.4, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height * 0.6);
    } else if (bottomLeft) {
      path.moveTo(0, size.height * 0.4);
      path.lineTo(0, size.height);
      path.lineTo(size.width * 0.6, size.height);
    } else if (bottomRight) {
      path.moveTo(size.width * 0.4, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height * 0.4);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
