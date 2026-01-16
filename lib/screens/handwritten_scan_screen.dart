// lib/screens/handwritten_scan_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/note_organization.dart';
import '../services/storage_service.dart';
import '../services/qr_share_helper.dart';
import '../services/p2p_file_share_service.dart';
import 'note_share_qr.dart';

enum ScanFilter { original, magic, highContrast, lighten, darken }

class HandwrittenScanScreen extends StatefulWidget {
  const HandwrittenScanScreen({super.key});

  @override
  State<HandwrittenScanScreen> createState() => _HandwrittenScanScreenState();
}

class _HandwrittenScanScreenState extends State<HandwrittenScanScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _cameraReady = false;

  // Store both file path and bytes for reliable preview
  final List<_ScannedPage> _pages = [];
  bool _savingPdf = false;
  bool _isCapturing = false;
  bool _flashOn = false;

  final TextEditingController _titleController =
      TextEditingController(text: "Scanned Notes");

  ScanFilter _filter = ScanFilter.magic;
  String _userClassId = 'class_10';

  @override
  void initState() {
    super.initState();
    _loadUserClass();
    _initCamera();
  }

  Future<void> _loadUserClass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classId = prefs.getString('profile_class_id');
      if (classId != null && mounted) {
        setState(() {
          _userClassId = classId;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user class: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("No camera found")));
          Navigator.pop(context);
        }
        return;
      }

      _cameraController = CameraController(
        cams.first,
        ResolutionPreset.high, // Higher resolution for better scans
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      await _initializeControllerFuture;
      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _cameraReady = true;
          _flashOn = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Camera error: $e")));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      final newState = !_flashOn;
      await _cameraController!
          .setFlashMode(newState ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = newState);
    } catch (_) {}
  }

  /// Samsung A12 safe image processing with reliable bytes output
  Future<_ScannedPage?> _processImage(File input) async {
    try {
      final originalBytes = await input.readAsBytes();

      // Step 1: Force JPEG conversion using flutter_image_compress (handles Samsung YUV/HEIC)
      Uint8List jpegBytes;
      try {
        jpegBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          format: CompressFormat.jpeg,
          quality: 92,
          minWidth: 1200,
          minHeight: 1600,
        );
      } catch (e) {
        // Fallback to original bytes if compression fails
        jpegBytes = Uint8List.fromList(originalBytes);
      }

      // Step 2: Decode and apply filter using image package
      img.Image? decoded;
      try {
        decoded = img.decodeJpg(jpegBytes);
      } catch (_) {
        try {
          decoded = img.decodeImage(jpegBytes);
        } catch (_) {
          // If decoding fails, just save original
          final docs = await getApplicationDocumentsDirectory();
          final outFile = File(p.join(
              docs.path, "scan_${DateTime.now().millisecondsSinceEpoch}.jpg"));
          await outFile.writeAsBytes(jpegBytes, flush: true);
          return _ScannedPage(file: outFile, thumbnailBytes: jpegBytes);
        }
      }

      if (decoded == null) {
        final docs = await getApplicationDocumentsDirectory();
        final outFile = File(p.join(
            docs.path, "scan_${DateTime.now().millisecondsSinceEpoch}.jpg"));
        await outFile.writeAsBytes(jpegBytes, flush: true);
        return _ScannedPage(file: outFile, thumbnailBytes: jpegBytes);
      }

      img.Image work = decoded;

      // Resize if too large
      if (work.width > 1500) {
        work = img.copyResize(work, width: 1500);
      }

      // Apply CamScanner-like filters using correct image package API
      switch (_filter) {
        case ScanFilter.original:
          // Minimal enhancement - slight contrast boost
          work = img.contrast(work, contrast: 105);
          break;

        case ScanFilter.magic:
          // CamScanner Magic Color - Professional document enhancement
          // Step 1: Auto white balance and normalize
          work = img.normalize(work, min: 0, max: 255);

          // Step 2: Adaptive histogram equalization for text clarity
          work = img.contrast(work, contrast: 140);

          // Step 3: Sharpen text edges
          work = img.adjustColor(work, contrast: 1.15);

          // Step 4: Brighten slightly and reduce yellow tint
          work = img.colorOffset(work, red: 12, green: 12, blue: 15);

          // Step 5: Enhance contrast in midtones for handwritten text
          work = img.adjustColor(work, saturation: 0.80, brightness: 1.05);

          // Step 6: Remove noise and smoothen background
          work = img.gaussianBlur(work, radius: 1);

          // Step 7: Final contrast boost for crisp text
          work = img.contrast(work, contrast: 110);
          break;

        case ScanFilter.highContrast:
          // High contrast B&W style for faded text
          work = img.grayscale(work);
          work = img.contrast(work, contrast: 160);
          work = img.colorOffset(work, red: 15, green: 15, blue: 15);
          break;

        case ScanFilter.lighten:
          // Brighten dark scans
          work = img.colorOffset(work, red: 40, green: 40, blue: 40);
          work = img.contrast(work, contrast: 115);
          break;

        case ScanFilter.darken:
          // Darken overexposed scans
          work = img.colorOffset(work, red: -30, green: -30, blue: -30);
          work = img.contrast(work, contrast: 125);
          break;
      }

      // Encode final image
      final processedBytes =
          Uint8List.fromList(img.encodeJpg(work, quality: 88));

      // Create thumbnail for preview (smaller size for faster loading)
      final thumbnail = img.copyResize(work, width: 200);
      final thumbnailBytes =
          Uint8List.fromList(img.encodeJpg(thumbnail, quality: 75));

      // Save to file
      final docs = await getApplicationDocumentsDirectory();
      final outFile = File(p.join(
          docs.path, "scan_${DateTime.now().millisecondsSinceEpoch}.jpg"));
      await outFile.writeAsBytes(processedBytes, flush: true);

      return _ScannedPage(file: outFile, thumbnailBytes: thumbnailBytes);
    } catch (e) {
      debugPrint("Image processing error: $e");
      // Fallback: just copy the original file
      try {
        final docs = await getApplicationDocumentsDirectory();
        final outFile = File(p.join(
            docs.path, "scan_${DateTime.now().millisecondsSinceEpoch}.jpg"));
        await input.copy(outFile.path);
        final bytes = await outFile.readAsBytes();
        return _ScannedPage(
            file: outFile, thumbnailBytes: Uint8List.fromList(bytes));
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _capturePage() async {
    if (_cameraController == null || _isCapturing) return;

    try {
      setState(() => _isCapturing = true);
      await _initializeControllerFuture;

      final xFile = await _cameraController!.takePicture();
      final original = File(xFile.path);

      final processed = await _processImage(original);

      if (processed != null && mounted) {
        setState(() => _pages.add(processed));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Page ${_pages.length} captured"),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.salmon,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Capture failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _saveAsPdf() async {
    if (_pages.isEmpty || _savingPdf) return;

    // Show mandatory save dialog first
    final result = await _showMandatorySaveDialog();
    if (result == null) return; // User cancelled

    setState(() => _savingPdf = true);

    try {
      final pdf = pw.Document(compress: true);

      for (final page in _pages) {
        // Compress image before adding to PDF
        final originalBytes = await page.file.readAsBytes();

        // Compress to reduce PDF size (quality 85 for good balance)
        final compressedBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          format: CompressFormat.jpeg,
          quality: 85,
          minWidth: 1200,
          minHeight: 1600,
        );

        // Create PDF page with compressed image
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => pw.Center(
              child: pw.Image(
                pw.MemoryImage(compressedBytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );
      }

      final docs = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outFile = File(p.join(docs.path, "scan_pdf_$timestamp.pdf"));

      // Save PDF with compression
      final pdfBytes = await pdf.save();
      await outFile.writeAsBytes(pdfBytes, flush: true);

      final fileSize = await outFile.length();
      debugPrint('📝 PDF saved: ${_formatFileSize(fileSize)}');

      // Verify file was created
      if (!await outFile.exists()) {
        throw "Failed to save PDF file";
      }

      // Save as organized note
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('organized_notes') ?? '[]';
      final notesList =
          (jsonDecode(notesJson) as List).cast<Map<String, dynamic>>();

      // Use class from dialog result, fallback to user's profile class
      final newNote = OrganizedNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result['name']!,
        content: 'Scanned document with ${_pages.length} pages',
        classId: result['classId'] ?? _userClassId,
        subjectId: result['subjectId']!,
        categoryId: 'scanned',
        createdAt: DateTime.now(),
        filePath: outFile.path,
        type: 'pdf',
      );

      notesList.add(newNote.toJson());
      await prefs.setString('organized_notes', jsonEncode(notesList));

      // Also save to old format for backward compatibility
      final notes = await StorageService.loadNotes();
      notes.add({
        "title": result['name']!,
        "timestamp": DateTime.now().toIso8601String(),
        "type": "pdf",
        "filePath": outFile.path,
        "pageCount": _pages.length,
      });
      await StorageService.saveNotes(notes);

      if (!mounted) return;

      // Show success dialog with options
      _showSaveSuccessDialog(outFile, result['name']!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("PDF save error: $e")));
      }
    } finally {
      if (mounted) setState(() => _savingPdf = false);
    }
  }

  void _showSaveSuccessDialog(File pdfFile, String title) async {
    final fileSize = await pdfFile.length();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("PDF Saved!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("\"$title\" saved with ${_pages.length} page(s)."),
            const SizedBox(height: 4),
            Text(
              "Size: ${_formatFileSize(fileSize)}",
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Path: ${pdfFile.path}",
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text("Done"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.salmon),
                ),
              );

              try {
                // Prepare QR payload with aggressive compression/automatic P2P
                final payload = await QRShareHelper.prepareForSharing(
                  title: title,
                  content: '',
                  filePath: pdfFile.path,
                  fileType: 'pdf',
                );

                if (!mounted) return;
                Navigator.pop(context); // Close loading

                // Show mode-specific feedback
                if (payload.type == QRDataType.p2p) {
                  // Automatic P2P mode for large files
                  debugPrint('📡 Large file detected, using P2P mode');

                  final hostInfo =
                      await P2PFileShareService.startHosting(pdfFile);

                  // Update payload with P2P session info
                  payload.data['sessionId'] = hostInfo.sessionId;
                  payload.data['ip'] = hostInfo.ip;
                  payload.data['port'] = hostInfo.port;
                  payload.data['networkName'] = hostInfo.networkName;

                  // Show seamless P2P mode indicator
                  if (hostInfo.networkName != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '🚀 P2P Mode • Connected to ${hostInfo.networkName}'),
                        backgroundColor: Colors.blue[700],
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            '🚀 P2P Mode • Connect to Wi-Fi for fast transfer'),
                        backgroundColor: Colors.orange[700],
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Setup',
                          textColor: Colors.white,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('📱 Wi-Fi Setup for P2P'),
                                content: SingleChildScrollView(
                                  child:
                                      Text(WiFiHelper.getHotspotInstructions()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                } else {
                  // Successfully compressed for inline QR
                  debugPrint('✓ File compressed for inline QR');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✓ QR Ready • Optimized'),
                      backgroundColor: Colors.green[700],
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }

                // Navigate to QR share screen
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteShareQR(
                      note: payload.toJson(),
                      detailedness: 1.0,
                    ),
                  ),
                ).then((_) {
                  // Stop P2P hosting when done
                  P2PFileShareService.stopHosting();
                  if (mounted) Navigator.pop(context, true);
                });
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('QR generation failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.qr_code),
            label: const Text("Share QR"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.salmon,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<Map<String, String>?> _showMandatorySaveDialog() async {
    final nameController = TextEditingController();
    String selectedSubjectId = 'other';
    String selectedClassId = _userClassId;
    bool hasError = false;

    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.save, color: AppColors.salmon, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Save Scanned Document',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Document Name *',
                    hintText: 'Enter document name (required)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: hasError && nameController.text.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    if (hasError) {
                      setDialogState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClassId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: NoteClass.allClasses.map((cls) {
                    return DropdownMenuItem(
                      value: cls.id,
                      child: Text(cls.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClassId = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: const Icon(Icons.book),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: Subject.allSubjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Row(
                        children: [
                          Text(subject.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              subject.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSubjectId = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will be saved as "Scanned Document" category',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  setDialogState(() {
                    hasError = true;
                  });
                } else {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'classId': selectedClassId,
                    'subjectId': selectedSubjectId,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _previewPage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text("Page ${index + 1}"),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black87,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _pages.removeAt(index));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            body: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51), // ~0.2 opacity
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _pages[index].file,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraReady || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("Initializing camera...",
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    // 3:4 aspect ratio for A4 paper scanning (wider view)
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera with 3:4 aspect ratio (A4 friendly)
        Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: CameraPreview(_cameraController!),
          ),
        ),

        // Flash toggle
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _toggleFlash,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128), // ~0.5 opacity
                shape: BoxShape.circle,
              ),
              child: Icon(
                _flashOn ? Icons.flash_on : Icons.flash_off,
                color: _flashOn ? Colors.yellow : Colors.white,
                size: 24,
              ),
            ),
          ),
        ),

        // Hint text
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153), // ~0.6 opacity
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Align your document and capture",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _filterLabel(ScanFilter f) {
    switch (f) {
      case ScanFilter.original:
        return "Original";
      case ScanFilter.magic:
        return "Magic";
      case ScanFilter.highContrast:
        return "B&W";
      case ScanFilter.lighten:
        return "Lighten";
      case ScanFilter.darken:
        return "Darken";
    }
  }

  IconData _filterIcon(ScanFilter f) {
    switch (f) {
      case ScanFilter.original:
        return Icons.image;
      case ScanFilter.magic:
        return Icons.auto_fix_high;
      case ScanFilter.highContrast:
        return Icons.contrast;
      case ScanFilter.lighten:
        return Icons.wb_sunny;
      case ScanFilter.darken:
        return Icons.nightlight;
    }
  }

  Widget _filterToolbar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: ScanFilter.values.map((f) {
          final selected = f == _filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.salmon
                      : Colors.white.withAlpha(204), // ~0.8 opacity
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: selected
                        ? AppColors.salmon
                        : Colors.grey.withAlpha(77), // ~0.3 opacity
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.salmon.withAlpha(102), // ~0.4 opacity
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _filterIcon(f),
                      size: 18,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _filterLabel(f),
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageThumbnails() {
    if (_pages.isEmpty) {
      return Container(
        height: 95,
        alignment: Alignment.center,
        child: Text(
          "No pages captured yet",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _pages.length,
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => _previewPage(i),
            child: Container(
              width: 65,
              height: 95,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 60,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.salmon
                                  .withAlpha(128)), // ~0.5 opacity
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26), // ~0.1 opacity
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.memory(
                            _pages[i].thumbnailBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 24),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => setState(() => _pages.removeAt(i)),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${i + 1}",
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(
            "Scan to PDF",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.black87),
          elevation: 0,
          actions: [
            if (_pages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.salmon.withAlpha(51), // ~0.2 opacity
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${_pages.length} page${_pages.length > 1 ? 's' : ''}",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // PDF Title input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "PDF Title",
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.title, color: AppColors.salmon),
                  filled: true,
                  fillColor: Colors.white.withAlpha(230), // ~0.9 opacity
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Camera preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51), // ~0.2 opacity
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildCameraPreview(),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Filter toolbar
            _filterToolbar(),

            // Page thumbnails
            _buildPageThumbnails(),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  // Undo button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230), // ~0.9 opacity
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26), // ~0.1 opacity
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _pages.isEmpty
                          ? null
                          : () => setState(() => _pages.removeLast()),
                      icon: Icon(
                        Icons.undo,
                        color: _pages.isEmpty ? Colors.grey : Colors.redAccent,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Capture button
                  GestureDetector(
                    onTap: _isCapturing ? null : _capturePage,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          width: 4,
                          color: _isCapturing ? Colors.grey : AppColors.salmon,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.salmon.withAlpha(102), // ~0.4 opacity
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isCapturing
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor:
                                      AlwaysStoppedAnimation(AppColors.salmon),
                                ),
                              )
                            : Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.salmon,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Save button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      onPressed:
                          _pages.isEmpty || _savingPdf ? null : _saveAsPdf,
                      icon: _savingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf, size: 20),
                      label: Text(_savingPdf ? "Saving..." : "Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _pages.isEmpty ? Colors.grey : AppColors.salmon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: _pages.isEmpty ? 0 : 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to store scanned page with both file and thumbnail bytes
class _ScannedPage {
  final File file;
  final Uint8List thumbnailBytes;

  _ScannedPage({required this.file, required this.thumbnailBytes});
}
