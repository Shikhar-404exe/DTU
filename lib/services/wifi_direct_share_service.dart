

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/note.dart';

enum WiFiShareState {
  idle,
  requestingPermissions,
  permissionsDenied,
  creatingHotspot,
  hotspotActive,
  searchingForHotspot,
  connecting,
  connected,
  transferring,
  completed,
  error,
}

class HotspotConfig {
  final String ssid;
  final String password;
  final String ipAddress;
  final int port;

  HotspotConfig({
    required this.ssid,
    required this.password,
    required this.ipAddress,
    this.port = 8888,
  });

  String get connectionUrl => 'http://$ipAddress:$port';
}

class WiFiDirectShareService {
  final _stateController = StreamController<WiFiShareState>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _receivedNotesController = StreamController<Note>.broadcast();

  WiFiShareState _currentState = WiFiShareState.idle;
  HttpServer? _server;
  HotspotConfig? _hotspotConfig;

  Stream<WiFiShareState> get stateStream => _stateController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Note> get receivedNotesStream => _receivedNotesController.stream;

  WiFiShareState get currentState => _currentState;
  HotspotConfig? get hotspotConfig => _hotspotConfig;

  Future<bool> initialize() async {
    _updateState(WiFiShareState.requestingPermissions);

    try {

      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        _updateState(WiFiShareState.permissionsDenied);
        _errorController.add('WiFi and Location permissions required');
        return false;
      }

      _updateState(WiFiShareState.idle);
      return true;
    } catch (e) {
      debugPrint('❌ WiFi Direct initialization error: $e');
      _updateState(WiFiShareState.error);
      _errorController.add('Failed to initialize: $e');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.location,
          Permission.nearbyWifiDevices,
        ].request();

        return statuses.values.every((status) => status.isGranted);
      }
      return true;
    } catch (e) {
      debugPrint('❌ Permission error: $e');
      return false;
    }
  }

  Future<bool> startAsSender() async {
    if (_currentState != WiFiShareState.idle) {
      return false;
    }

    _updateState(WiFiShareState.creatingHotspot);

    try {

      final networkInfo = NetworkInfo();
      String? ipAddress = await networkInfo.getWifiIP();

      ipAddress ??= '192.168.43.1';

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8888);

      _hotspotConfig = HotspotConfig(
        ssid:
            'Vidyarthi-Share-${DateTime.now().millisecondsSinceEpoch % 10000}',
        password: _generatePassword(),
        ipAddress: ipAddress,
      );

      debugPrint('📡 WiFi Hotspot created:');
      debugPrint('   SSID: ${_hotspotConfig!.ssid}');
      debugPrint('   Password: ${_hotspotConfig!.password}');
      debugPrint('   IP: ${_hotspotConfig!.ipAddress}');
      debugPrint('   URL: ${_hotspotConfig!.connectionUrl}');

      _server!.listen(_handleRequest);

      _updateState(WiFiShareState.hotspotActive);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start hotspot: $e');
      _updateState(WiFiShareState.error);
      _errorController.add('Failed to start hotspot: $e');
      return false;
    }
  }

  void _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/') {

        request.response
          ..statusCode = HttpStatus.ok
          ..write('Vidyarthi Share Server Active')
          ..close();
      } else if (request.method == 'POST' && request.uri.path == '/receive') {

        request.response
          ..statusCode = HttpStatus.ok
          ..write('OK')
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    } catch (e) {
      debugPrint('❌ Request handling error: $e');
    }
  }

  Future<bool> sendNote(Note note, String recipientIp) async {
    if (_currentState != WiFiShareState.hotspotActive) {
      _errorController.add('Hotspot not active');
      return false;
    }

    _updateState(WiFiShareState.transferring);

    try {

      final noteData = {
        'type': 'note',
        'data': note.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(noteData);

      final client = HttpClient();
      final request =
          await client.postUrl(Uri.parse('http://$recipientIp:8889/receive'));
      request.headers.contentType = ContentType.json;
      request.write(jsonString);

      final response = await request.close();

      if (response.statusCode == 200) {
        debugPrint('✅ Note sent successfully to $recipientIp');
        _updateState(WiFiShareState.completed);
        return true;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Failed to send note: $e');
      _updateState(WiFiShareState.error);
      _errorController.add('Failed to send: $e');
      return false;
    }
  }

  Future<int> broadcastNote(Note note) async {
    if (_currentState != WiFiShareState.hotspotActive) {
      _errorController.add('Hotspot not active');
      return 0;
    }

    _updateState(WiFiShareState.transferring);
    int successCount = 0;

    try {

      final noteData = {
        'type': 'note',
        'data': note.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(noteData);
      final bytes = utf8.encode(jsonString);

      debugPrint('📤 Broadcasting note: ${note.topic}');
      debugPrint('   Size: ${bytes.length} bytes');

      final baseIp = '192.168.43';
      final futures = <Future<bool>>[];

      for (int i = 2; i <= 20; i++) {

        final ip = '$baseIp.$i';
        futures.add(_sendToDevice(ip, jsonString));
      }

      final results = await Future.wait(futures);
      successCount = results.where((success) => success).length;

      debugPrint('✅ Note sent to $successCount devices');
      _updateState(WiFiShareState.completed);
      return successCount;
    } catch (e) {
      debugPrint('❌ Broadcast error: $e');
      _updateState(WiFiShareState.error);
      _errorController.add('Broadcast failed: $e');
      return successCount;
    }
  }

  Future<bool> _sendToDevice(String ip, String data) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);

      final request =
          await client.postUrl(Uri.parse('http://$ip:8889/receive'));
      request.headers.contentType = ContentType.json;
      request.write(data);

      final response = await request.close();
      await response.drain();

      if (response.statusCode == 200) {
        debugPrint('✅ Sent to $ip');
        return true;
      }
      return false;
    } catch (e) {

      return false;
    }
  }

  Future<bool> startAsReceiver() async {
    if (_currentState != WiFiShareState.idle) {
      return false;
    }

    _updateState(WiFiShareState.searchingForHotspot);

    try {

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8889);

      debugPrint('📥 Receiver started on port 8889');

      _server!.listen((request) async {
        if (request.method == 'POST' && request.uri.path == '/receive') {
          await _handleReceivedNote(request);
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('Receiver Active')
            ..close();
        }
      });

      _updateState(WiFiShareState.connected);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start receiver: $e');
      _updateState(WiFiShareState.error);
      _errorController.add('Failed to start receiver: $e');
      return false;
    }
  }

  Future<void> _handleReceivedNote(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      final jsonData = jsonDecode(body);

      if (jsonData['type'] == 'note') {
        final note = Note.fromJson(jsonData['data'] as Map<String, dynamic>);
        debugPrint('📥 Received note: ${note.topic}');

        _receivedNotesController.add(note);

        request.response
          ..statusCode = HttpStatus.ok
          ..write('Note received')
          ..close();
      }
    } catch (e) {
      debugPrint('❌ Failed to parse note: $e');
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Error: $e')
        ..close();
    }
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[(random + index) % chars.length])
        .join();
  }

  void _updateState(WiFiShareState newState) {
    _currentState = newState;
    _stateController.add(newState);
    debugPrint('🔄 WiFi State: $newState');
  }

  Future<void> stop() async {
    try {
      await _server?.close();
      _server = null;
      _hotspotConfig = null;
      _updateState(WiFiShareState.idle);
      debugPrint('🛑 WiFi Direct service stopped');
    } catch (e) {
      debugPrint('❌ Error stopping service: $e');
    }
  }

  void dispose() {
    stop();
    _stateController.close();
    _progressController.close();
    _errorController.close();
    _receivedNotesController.close();
  }
}
