/// Bluetooth sharing service for peer-to-peer note sharing
/// Enables teacher to broadcast notes to entire class via Bluetooth
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../models/note.dart';

/// Connection state for Bluetooth sharing
enum BluetoothShareState {
  idle,
  requestingPermissions,
  permissionsDenied,
  discovering,
  broadcasting,
  connected,
  transferring,
  completed,
  error,
}

/// Device discovered nearby
class DiscoveredDevice {
  final String id;
  final String displayName;
  final int state; // 0=available, 1=connected, 2=connecting

  DiscoveredDevice({
    required this.id,
    required this.displayName,
    required this.state,
  });

  bool get isAvailable => state == 0;
  bool get isConnected => state == 1;
  bool get isConnecting => state == 2;
}

/// Transfer progress data
class TransferProgress {
  final String deviceId;
  final String deviceName;
  final int bytesTransferred;
  final int totalBytes;

  TransferProgress({
    required this.deviceId,
    required this.deviceName,
    required this.bytesTransferred,
    required this.totalBytes,
  });

  double get percentage => totalBytes > 0 ? (bytesTransferred / totalBytes) : 0;
}

/// Bluetooth sharing service - One-to-many broadcasting
class BluetoothShareService {
  NearbyService? _nearbyService;
  final _stateController = StreamController<BluetoothShareState>.broadcast();
  final _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();
  final _progressController = StreamController<TransferProgress>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  final List<DiscoveredDevice> _discoveredDevices = [];
  final Map<String, int> _transferProgress = {};

  BluetoothShareState _currentState = BluetoothShareState.idle;
  String? _deviceName;

  // Streams
  Stream<BluetoothShareState> get stateStream => _stateController.stream;
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;
  Stream<TransferProgress> get progressStream => _progressController.stream;
  Stream<String> get errorStream => _errorController.stream;

  BluetoothShareState get currentState => _currentState;
  List<DiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  /// Initialize Bluetooth service and request permissions
  Future<bool> initialize() async {
    _updateState(BluetoothShareState.requestingPermissions);

    try {
      // Get device name
      _deviceName = await _getDeviceName();
      debugPrint('📱 Device name: $_deviceName');

      // Request permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        _updateState(BluetoothShareState.permissionsDenied);
        _errorController.add('Bluetooth and Location permissions are required');
        return false;
      }

      _updateState(BluetoothShareState.idle);
      return true;
    } catch (e) {
      debugPrint('❌ Bluetooth initialization error: $e');
      _updateState(BluetoothShareState.error);
      _errorController.add('Failed to initialize Bluetooth: $e');
      return false;
    }
  }

  /// Request necessary permissions (Bluetooth, Location)
  Future<bool> _requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // Android 12+ (API 31+) requires new Bluetooth permissions
        if (androidInfo.version.sdkInt >= 31) {
          statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothAdvertise,
            Permission.bluetoothConnect,
            Permission.nearbyWifiDevices,
          ].request();
        } else {
          // Android 11 and below
          statuses = await [
            Permission.bluetooth,
            Permission.location,
          ].request();
        }
      } else {
        // iOS
        statuses = await [
          Permission.bluetooth,
        ].request();
      }

      final allGranted = statuses.values.every((status) => status.isGranted);
      debugPrint('📋 Permissions granted: $allGranted');
      return allGranted;
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      return false;
    }
  }

  /// Get device name for display
  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Start broadcasting as sender (Teacher mode)
  /// Allows multiple receivers to connect and receive notes
  Future<bool> startBroadcasting() async {
    if (_currentState != BluetoothShareState.idle) {
      debugPrint('⚠️ Already in state: $_currentState');
      return false;
    }

    _updateState(BluetoothShareState.broadcasting);
    _discoveredDevices.clear();

    try {
      _nearbyService = NearbyService();
      await _nearbyService!.init(
        serviceType: 'vidyarthi-share',
        deviceName: _deviceName ?? 'Teacher',
        strategy: Strategy.P2P_CLUSTER, // One-to-many broadcasting
        callback: (isRunning) {
          debugPrint('📡 Nearby service running: $isRunning');
        },
      );

      // Listen for connected devices
      _nearbyService!.stateChangedSubscription(callback: (devices) {
        _updateDiscoveredDevices(devices);
      });

      // Listen for incoming data (not used in sender mode, but required)
      _nearbyService!.dataReceivedSubscription(callback: (data) {
        debugPrint('📥 Data received from ${data.sender}: ${data.message}');
      });

      debugPrint('✅ Broadcasting started: $_deviceName');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start broadcasting: $e');
      _updateState(BluetoothShareState.error);
      _errorController.add('Failed to start broadcasting: $e');
      return false;
    }
  }

  /// Start discovery as receiver (Student mode)
  /// Discovers nearby teachers broadcasting notes
  Future<bool> startDiscovery() async {
    if (_currentState != BluetoothShareState.idle) {
      debugPrint('⚠️ Already in state: $_currentState');
      return false;
    }

    _updateState(BluetoothShareState.discovering);
    _discoveredDevices.clear();

    try {
      _nearbyService = NearbyService();
      await _nearbyService!.init(
        serviceType: 'vidyarthi-share',
        deviceName: _deviceName ?? 'Student',
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) {
          debugPrint('🔍 Discovery running: $isRunning');
        },
      );

      // Listen for discovered devices
      _nearbyService!.stateChangedSubscription(callback: (devices) {
        _updateDiscoveredDevices(devices);
      });

      // Listen for incoming data
      _nearbyService!.dataReceivedSubscription(callback: (data) {
        _handleReceivedData(data);
      });

      debugPrint('✅ Discovery started');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start discovery: $e');
      _updateState(BluetoothShareState.error);
      _errorController.add('Failed to start discovery: $e');
      return false;
    }
  }

  /// Connect to a discovered device (Student connects to Teacher)
  Future<bool> connectToDevice(String deviceId) async {
    try {
      await _nearbyService?.invitePeer(
        deviceID: deviceId,
        deviceName: _deviceName ?? 'Student',
      );
      debugPrint('📞 Sent connection invite to $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to connect: $e');
      _errorController.add('Failed to connect: $e');
      return false;
    }
  }

  /// Send note to all connected devices (Teacher broadcasts to Students)
  Future<void> sendNoteToAll(Note note) async {
    if (_nearbyService == null) {
      _errorController.add('Service not initialized');
      return;
    }

    _updateState(BluetoothShareState.transferring);

    try {
      // Prepare note data
      final noteData = {
        'type': 'note',
        'data': note.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(noteData);
      final bytes = utf8.encode(jsonString);

      // Get connected devices
      final connectedDevices =
          _discoveredDevices.where((d) => d.isConnected).toList();

      if (connectedDevices.isEmpty) {
        _errorController.add('No devices connected');
        _updateState(BluetoothShareState.broadcasting);
        return;
      }

      debugPrint('📤 Sending note to ${connectedDevices.length} devices');
      debugPrint('   Size: ${bytes.length} bytes');

      // Send to all connected devices
      for (final device in connectedDevices) {
        await _sendDataInChunks(device.id, bytes);
      }

      _updateState(BluetoothShareState.completed);
      debugPrint('✅ Note sent to all connected devices');
    } catch (e) {
      debugPrint('❌ Failed to send note: $e');
      _updateState(BluetoothShareState.error);
      _errorController.add('Failed to send note: $e');
    }
  }

  /// Send data in chunks (Bluetooth has packet size limits)
  Future<void> _sendDataInChunks(String deviceId, Uint8List data) async {
    const chunkSize = 512; // 512 bytes per chunk
    final totalChunks = (data.length / chunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end =
          (start + chunkSize < data.length) ? start + chunkSize : data.length;

      final chunk = data.sublist(start, end);

      await _nearbyService?.sendMessage(deviceId, String.fromCharCodes(chunk));

      // Update progress
      _transferProgress[deviceId] = end;
      _progressController.add(TransferProgress(
        deviceId: deviceId,
        deviceName: _getDeviceName(deviceId),
        bytesTransferred: end,
        totalBytes: data.length,
      ));

      // Small delay to prevent overwhelming Bluetooth
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Handle received data (Student receives note from Teacher)
  void _handleReceivedData(dynamic data) {
    try {
      final message = data.message as String;
      final jsonData = jsonDecode(message);

      if (jsonData['type'] == 'note') {
        final note = Note.fromJson(jsonData['data'] as Map<String, dynamic>);
        debugPrint('📥 Received note: ${note.topic}');

        // Emit received note through stream
        // TODO: Add received notes stream
        _updateState(BluetoothShareState.completed);
      }
    } catch (e) {
      debugPrint('❌ Failed to parse received data: $e');
    }
  }

  /// Update discovered devices list
  void _updateDiscoveredDevices(dynamic devicesData) {
    _discoveredDevices.clear();

    if (devicesData is List) {
      for (final device in devicesData) {
        _discoveredDevices.add(DiscoveredDevice(
          id: device.deviceId as String,
          displayName: device.deviceName as String,
          state: device.state as int,
        ));
      }
    }

    _devicesController.add(_discoveredDevices);
    debugPrint('👥 Discovered devices: ${_discoveredDevices.length}');
  }

  /// Get device name by ID
  String _getDeviceName(String deviceId) {
    final device = _discoveredDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () =>
          DiscoveredDevice(id: deviceId, displayName: 'Unknown', state: 0),
    );
    return device.displayName;
  }

  /// Update state and notify listeners
  void _updateState(BluetoothShareState newState) {
    _currentState = newState;
    _stateController.add(newState);
    debugPrint('🔄 State: $newState');
  }

  /// Stop broadcasting/discovery and cleanup
  Future<void> stop() async {
    try {
      await _nearbyService?.stopBrowsingForPeers();
      await _nearbyService?.stopAdvertisingPeer();
      _discoveredDevices.clear();
      _transferProgress.clear();
      _updateState(BluetoothShareState.idle);
      debugPrint('🛑 Bluetooth service stopped');
    } catch (e) {
      debugPrint('❌ Error stopping service: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
    _stateController.close();
    _devicesController.close();
    _progressController.close();
    _errorController.close();
  }
}
