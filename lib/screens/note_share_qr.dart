import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/p2p_file_share_service.dart';
import '../services/qr_share_helper.dart';

class NoteShareQR extends StatefulWidget {
  final String note;
  final double detailedness;

  const NoteShareQR({
    super.key,
    required this.note,
    required this.detailedness,
  });

  @override
  State<NoteShareQR> createState() => _NoteShareQRState();
}

class _NoteShareQRState extends State<NoteShareQR> {
  QRPayload? _payload;
  String? _qrData;
  bool _loading = true;
  String? _error;
  String? _networkName;

  @override
  void initState() {
    super.initState();
    _initPayload();
  }

  @override
  void dispose() {

    P2PFileShareService.stopHosting();
    super.dispose();
  }

  void _initPayload() async {
    try {

      _payload = QRPayload.fromJson(widget.note);

      if (_payload!.type == QRDataType.p2p) {

        await _startP2PHosting();
      } else {

        _qrData = widget.note;
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error preparing QR: $e";
        _loading = false;
      });
    }
  }

  Future<void> _startP2PHosting() async {
    try {
      final data = _payload!.data;
      final filePath = data['filePath'] as String?;

      if (filePath == null) {
        throw Exception('P2P mode requires filePath');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final hostInfo = await P2PFileShareService.startHosting(file);

      data['sessionId'] = hostInfo.sessionId;
      data['ip'] = hostInfo.ip;
      data['port'] = hostInfo.port;
      data['networkName'] = hostInfo.networkName;

      _networkName = hostInfo.networkName;

      _qrData = jsonEncode({
        'v': 2,
        'type': 'p2p',
        'data': data,
      });

      debugPrint('✓ P2P hosting started: ${hostInfo.ip}:${hostInfo.port}');
    } catch (e) {
      throw Exception('Failed to start P2P hosting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isP2P = _payload?.type == QRDataType.p2p;
    final title = _payload?.data['title'] as String? ?? 'Shared Note';

    return Container(
      color: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFFFDAD0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            isP2P ? "Share via P2P" : "Share Note via QR",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.black87),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _loading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.salmon),
                      const SizedBox(height: 16),
                      Text(
                        isP2P ? 'Starting P2P hosting...' : 'Preparing QR...',
                        style: TextStyle(
                          color:
                              isDark ? AppColors.textLightDark : Colors.black87,
                        ),
                      ),
                    ],
                  )
                : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48,
                              color: isDark ? Colors.redAccent : Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: isDark ? Colors.redAccent : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : _buildContent(isDark, title),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, String title) {
    if (_qrData == null || _payload == null) {
      return Text(
        "No data for QR.",
        style: TextStyle(
          color: isDark ? AppColors.textLightDark : Colors.black54,
        ),
      );
    }

    final isP2P = _payload!.type == QRDataType.p2p;
    final isCompressed = _payload!.data['compressed'] == true;

    final qrWidget = QrImageView(
      data: _qrData!,
      version: QrVersions.auto,
      gapless: false,
      size: 260,
      foregroundColor: Colors.black,
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          if (isP2P)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi, color: Colors.blue, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚀 P2P Mode Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade800,
                          ),
                        ),
                        if (_networkName != null)
                          Text(
                            'Connected to: $_networkName',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (isCompressed)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.compress, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '✓ Optimized & Compressed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.green.shade200
                          : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),

          Card(
            elevation: 12,
            shadowColor: isDark ? Colors.black45 : Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white,
              ),
              child: qrWidget,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.textDarkMode : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          if (isP2P)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.shade900.withOpacity(0.2)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "📱 P2P Transfer Instructions",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDarkMode : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "1. Connect receiver to same Wi-Fi${_networkName != null ? '\n   (Network: $_networkName)' : ''}\n"
                    "2. Open Scan QR tab on receiver\n"
                    "3. Scan this QR code\n"
                    "4. File transfers automatically!",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textLightDark : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              "Scan this QR code in the Scan QR tab\nto receive this note instantly!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textLightDark : Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}
