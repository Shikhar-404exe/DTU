import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Wi-Fi Hotspot Helper
class WiFiHelper {
  /// Check if device is connected to Wi-Fi
  static Future<bool> isConnectedToWiFi() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      return wifiIP != null && wifiIP.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get current Wi-Fi IP address
  static Future<String?> getWiFiIP() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP();
    } catch (_) {
      return null;
    }
  }

  /// Get Wi-Fi SSID (network name)
  static Future<String?> getWiFiName() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiName();
    } catch (_) {
      return null;
    }
  }

  /// Get hotspot setup instructions
  static String getHotspotInstructions() {
    return '''📱 Hotspot Setup Instructions:

SENDER (Sharing Device):
1. Open Settings → Connections
2. Enable Mobile Hotspot
3. Note the hotspot name and password
4. Return to app and start sharing

RECEIVER (Receiving Device):
1. Open Settings → Wi-Fi
2. Connect to sender's hotspot
3. Return to app and scan QR code

⚠️ Both devices must be on the SAME network!

Alternatives:
• Use same Wi-Fi network
• One device creates hotspot, other connects''';
  }
}

/// Info about the hosting side (sender) for P2P file sharing.
class P2PHostInfo {
  final String sessionId;
  final String ip;
  final int port;
  final String fileName;
  final int fileSize;
  final String? networkName; // Wi-Fi SSID or hotspot name

  P2PHostInfo({
    required this.sessionId,
    required this.ip,
    required this.port,
    required this.fileName,
    required this.fileSize,
    this.networkName,
  });

  Map<String, dynamic> toJson() => {
        "v": 2,
        "kind": "p2p_file",
        "sessionId": sessionId,
        "ip": ip,
        "port": port,
        "fileName": fileName,
        "fileSize": fileSize,
        "networkName": networkName,
      };

  factory P2PHostInfo.fromJson(Map<String, dynamic> json) {
    return P2PHostInfo(
      sessionId: json['sessionId'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      networkName: json['networkName'] as String?,
    );
  }
}

/// Simple HTTP-based P2P file transfer over local Wi-Fi / hotspot.
/// - Sender starts a small HttpServer hosting the file.
/// - QR contains ip/port/sessionId.
/// - Receiver downloads via HTTP using that info.
/// No internet required, only local network.
class P2PFileShareService {
  static HttpServer? _server;
  static String? _currentSessionId;
  static File? _currentFile;

  /// Start hosting [file] on a random free port.
  /// Returns [P2PHostInfo] used to build handshake QR.
  static Future<P2PHostInfo> startHosting(File file) async {
    // Stop any previous server.
    await stopHosting();

    // Check if connected to Wi-Fi
    final isConnected = await WiFiHelper.isConnectedToWiFi();
    if (!isConnected) {
      debugPrint('⚠️ Warning: Not connected to Wi-Fi. P2P may not work.');
    } else {
      final networkName = await WiFiHelper.getWiFiName();
      debugPrint('✓ Connected to: ${networkName ?? "Unknown network"}');
    }

    _currentFile = file;
    _currentSessionId = const Uuid().v4();

    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      0, // random free port
    );
    _server = server;

    debugPrint('🌐 P2P Server started on port ${server.port}');

    // Start listening (simple single-file HTTP endpoint).
    _server!.listen((HttpRequest request) async {
      try {
        if (request.uri.path == '/file/$_currentSessionId') {
          if (_currentFile == null || !await _currentFile!.exists()) {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            return;
          }

          final fileLength = await _currentFile!.length();
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.set(
            HttpHeaders.contentTypeHeader,
            "application/octet-stream",
          );
          request.response.headers.set(
            HttpHeaders.contentLengthHeader,
            fileLength.toString(),
          );
          request.response.headers.set(
            "Content-Disposition",
            'attachment; filename="${p.basename(_currentFile!.path)}"',
          );

          final stream = _currentFile!.openRead();
          await request.response.addStream(stream);
          await request.response.close();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      } catch (_) {
        try {
          await request.response.close();
        } catch (_) {}
      }
    });

    // Determine IP to advertise.
    String? ip;
    String? networkName;
    try {
      final info = NetworkInfo();
      ip = await info.getWifiIP();
      networkName = await info.getWifiName();
    } catch (_) {
      ip = null;
      networkName = null;
    }
    // Fallback to bound address.
    ip ??= server.address.address;

    final size = await file.length();

    debugPrint(
        '📤 Sharing: ${p.basename(file.path)} (${_formatFileSize(size)})');
    debugPrint('🔗 Access at: http://$ip:${server.port}');

    return P2PHostInfo(
      sessionId: _currentSessionId!,
      ip: ip,
      port: server.port,
      fileName: p.basename(file.path),
      fileSize: size,
      networkName: networkName,
    );
  }

  /// Start hosting a file from its path.
  /// Convenience method that creates a File from path.
  static Future<P2PHostInfo> startHostingPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw "File not found: $filePath";
    }
    return startHosting(file);
  }

  /// Stop hosting file, if any.
  static Future<void> stopHosting() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _currentSessionId = null;
    _currentFile = null;
  }

  /// Download a file from [ip]:[port]/file/[sessionId] and save locally.
  /// Returns the saved File.
  static Future<File> downloadFile({
    required String ip,
    required int port,
    required String sessionId,
    required String suggestedName,
  }) async {
    debugPrint('📥 Downloading from http://$ip:$port...');

    final url = Uri.parse("http://$ip:$port/file/$sessionId");

    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        throw "Sender not reachable or file not available (HTTP ${resp.statusCode}). "
            "Ensure both devices are on the same Wi-Fi / hotspot.";
      }

      debugPrint('✓ Downloaded ${_formatFileSize(resp.bodyBytes.length)}');

      final docsDir = await getApplicationDocumentsDirectory();
      final cleanName =
          suggestedName.isNotEmpty ? suggestedName : "imported_file";
      final filePath = p.join(
        docsDir.path,
        "p2p_${DateTime.now().millisecondsSinceEpoch}_$cleanName",
      );

      final file = File(filePath);
      await file.writeAsBytes(resp.bodyBytes, flush: true);

      debugPrint('💾 Saved to: $filePath');
      return file;
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      rethrow;
    }
  }

  /// Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
