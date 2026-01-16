

library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../models/note.dart';

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
  unavailable,
}

class DiscoveredDevice {
  final String id;
  final String displayName;
  final int state;

  DiscoveredDevice({
    required this.id,
    required this.displayName,
    required this.state,
  });

  bool get isAvailable => state == 0;
  bool get isConnected => state == 1;
  bool get isConnecting => state == 2;
}

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

class BluetoothShareService {
  final _stateController = StreamController<BluetoothShareState>.broadcast();
  final _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();
  final _progressController = StreamController<TransferProgress>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  final List<DiscoveredDevice> _discoveredDevices = [];

  BluetoothShareState _currentState = BluetoothShareState.idle;
  String? _deviceName;

  Stream<BluetoothShareState> get stateStream => _stateController.stream;
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;
  Stream<TransferProgress> get progressStream => _progressController.stream;
  Stream<String> get errorStream => _errorController.stream;

  BluetoothShareState get currentState => _currentState;
  List<DiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  Future<bool> initialize() async {
    _updateState(BluetoothShareState.requestingPermissions);

    try {

      _deviceName = await _getDeviceName();
      debugPrint('📱 Device name: $_deviceName');

      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        _updateState(BluetoothShareState.permissionsDenied);
        _errorController.add('Bluetooth and Location permissions are required');
        return false;
      }

      _updateState(BluetoothShareState.unavailable);
      _errorController.add('Proximity sharing is temporarily unavailable. '
          'Please use QR code sharing instead.');
      return false;
    } catch (e) {
      debugPrint('❌ Bluetooth initialization error: $e');
      _updateState(BluetoothShareState.error);
      _errorController.add('Failed to initialize Bluetooth: $e');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 31) {
          statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothAdvertise,
            Permission.bluetoothConnect,
            Permission.nearbyWifiDevices,
          ].request();
        } else {

          statuses = await [
            Permission.bluetooth,
            Permission.location,
          ].request();
        }
      } else {

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

  Future<bool> startBroadcasting() async {
    _errorController.add('Proximity sharing is temporarily unavailable. '
        'Please use QR code sharing to share notes with students.');
    _updateState(BluetoothShareState.unavailable);
    return false;
  }

  Future<bool> startDiscovery() async {
    _errorController.add('Proximity sharing is temporarily unavailable. '
        'Please ask your teacher to share via QR code.');
    _updateState(BluetoothShareState.unavailable);
    return false;
  }

  Future<bool> connectToDevice(String deviceId) async {
    _errorController.add('Proximity sharing is temporarily unavailable.');
    return false;
  }

  Future<void> sendNoteToAll(Note note) async {
    _errorController.add('Proximity sharing is temporarily unavailable. '
        'Please use QR code sharing instead.');
  }

  void _updateState(BluetoothShareState newState) {
    _currentState = newState;
    _stateController.add(newState);
    debugPrint('🔄 Bluetooth State: $newState');
  }

  Future<void> stop() async {
    _discoveredDevices.clear();
    _updateState(BluetoothShareState.idle);
    debugPrint('🛑 Bluetooth service stopped');
  }

  void dispose() {
    stop();
    _stateController.close();
    _devicesController.close();
    _progressController.close();
    _errorController.close();
  }
}
