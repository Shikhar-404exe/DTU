/// Unified proximity sharing service
/// Orchestrates Bluetooth and WiFi Direct for seamless note sharing
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/note.dart';
import 'bluetooth_share_service.dart';
import 'wifi_direct_share_service.dart';

/// Sharing mode selection
enum ShareMode {
  bluetooth, // Slower, longer range (10-100m), lower power
  wifiDirect, // Faster, shorter range (10-50m), higher power
  auto, // Automatically select best mode
}

/// Proximity sharing state
enum ProximityShareState {
  idle,
  initializing,
  ready,
  discovering,
  broadcasting,
  transferring,
  completed,
  error,
}

/// Unified device for both Bluetooth and WiFi
class ProximityDevice {
  final String id;
  final String name;
  final ShareMode mode;
  final bool isAvailable;

  ProximityDevice({
    required this.id,
    required this.name,
    required this.mode,
    required this.isAvailable,
  });
}

/// Unified proximity sharing service
/// Manages both Bluetooth and WiFi Direct simultaneously
class ProximityShareService {
  final BluetoothShareService _bluetoothService;
  final WiFiDirectShareService _wifiService;

  final _stateController = StreamController<ProximityShareState>.broadcast();
  final _devicesController =
      StreamController<List<ProximityDevice>>.broadcast();
  final _receivedNotesController = StreamController<Note>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  ProximityShareState _currentState = ProximityShareState.idle;
  ShareMode _preferredMode = ShareMode.auto;

  // Streams
  Stream<ProximityShareState> get stateStream => _stateController.stream;
  Stream<List<ProximityDevice>> get devicesStream => _devicesController.stream;
  Stream<Note> get receivedNotesStream => _receivedNotesController.stream;
  Stream<String> get errorStream => _errorController.stream;

  ProximityShareState get currentState => _currentState;

  ProximityShareService({
    BluetoothShareService? bluetoothService,
    WiFiDirectShareService? wifiService,
  })  : _bluetoothService = bluetoothService ?? BluetoothShareService(),
        _wifiService = wifiService ?? WiFiDirectShareService() {
    _setupListeners();
  }

  /// Setup listeners for sub-services
  void _setupListeners() {
    // Bluetooth device updates
    _bluetoothService.devicesStream.listen((devices) {
      _updateDevicesList();
    });

    // WiFi received notes
    _wifiService.receivedNotesStream.listen((note) {
      _receivedNotesController.add(note);
    });

    // Error handling
    _bluetoothService.errorStream.listen((error) {
      _errorController.add('Bluetooth: $error');
    });

    _wifiService.errorStream.listen((error) {
      _errorController.add('WiFi: $error');
    });
  }

  /// Initialize both services
  Future<bool> initialize({ShareMode preferredMode = ShareMode.auto}) async {
    _updateState(ProximityShareState.initializing);
    _preferredMode = preferredMode;

    try {
      // Initialize both services in parallel
      final results = await Future.wait([
        _bluetoothService.initialize(),
        _wifiService.initialize(),
      ]);

      final bluetoothReady = results[0];
      final wifiReady = results[1];

      debugPrint('📱 Bluetooth ready: $bluetoothReady');
      debugPrint('📡 WiFi ready: $wifiReady');

      if (!bluetoothReady && !wifiReady) {
        _updateState(ProximityShareState.error);
        _errorController.add('Both Bluetooth and WiFi initialization failed');
        return false;
      }

      _updateState(ProximityShareState.ready);
      return true;
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      _updateState(ProximityShareState.error);
      return false;
    }
  }

  /// Start as sender (Teacher mode)
  /// Broadcasts via both Bluetooth and WiFi for maximum reach
  Future<bool> startSending() async {
    if (_currentState != ProximityShareState.ready) {
      return false;
    }

    _updateState(ProximityShareState.broadcasting);

    try {
      // Start both services
      final results = await Future.wait([
        _bluetoothService.startBroadcasting(),
        _wifiService.startAsSender(),
      ]);

      final bluetoothStarted = results[0];
      final wifiStarted = results[1];

      debugPrint('✅ Broadcasting started:');
      debugPrint('   Bluetooth: $bluetoothStarted');
      debugPrint('   WiFi: $wifiStarted');

      if (wifiStarted && _wifiService.hotspotConfig != null) {
        final config = _wifiService.hotspotConfig!;
        debugPrint('\n📡 Students should connect to:');
        debugPrint('   WiFi: ${config.ssid}');
        debugPrint('   Password: ${config.password}');
      }

      return bluetoothStarted || wifiStarted;
    } catch (e) {
      debugPrint('❌ Failed to start sending: $e');
      _updateState(ProximityShareState.error);
      return false;
    }
  }

  /// Start as receiver (Student mode)
  /// Discovers teachers via both Bluetooth and WiFi
  Future<bool> startReceiving() async {
    if (_currentState != ProximityShareState.ready) {
      return false;
    }

    _updateState(ProximityShareState.discovering);

    try {
      // Start discovery on both services
      final results = await Future.wait([
        _bluetoothService.startDiscovery(),
        _wifiService.startAsReceiver(),
      ]);

      final bluetoothStarted = results[0];
      final wifiStarted = results[1];

      debugPrint('✅ Discovery started:');
      debugPrint('   Bluetooth: $bluetoothStarted');
      debugPrint('   WiFi: $wifiStarted');

      return bluetoothStarted || wifiStarted;
    } catch (e) {
      debugPrint('❌ Failed to start receiving: $e');
      _updateState(ProximityShareState.error);
      return false;
    }
  }

  /// Send note to all connected devices
  /// Uses both Bluetooth and WiFi for maximum coverage
  Future<void> sendNoteToAll(Note note) async {
    _updateState(ProximityShareState.transferring);

    try {
      debugPrint('📤 Sending note via proximity share: ${note.topic}');

      // Send via both channels simultaneously
      await Future.wait([
        _bluetoothService.sendNoteToAll(note),
        _wifiService.broadcastNote(note),
      ]);

      debugPrint('✅ Note sent via proximity share');
      _updateState(ProximityShareState.completed);
    } catch (e) {
      debugPrint('❌ Failed to send note: $e');
      _updateState(ProximityShareState.error);
      _errorController.add('Failed to send: $e');
    }
  }

  /// Connect to specific device (Student connects to Teacher)
  Future<bool> connectToDevice(ProximityDevice device) async {
    if (device.mode == ShareMode.bluetooth) {
      return await _bluetoothService.connectToDevice(device.id);
    } else if (device.mode == ShareMode.wifiDirect) {
      // WiFi Direct connection happens automatically when on same network
      return true;
    }
    return false;
  }

  /// Update unified devices list from both services
  void _updateDevicesList() {
    final devices = <ProximityDevice>[];

    // Add Bluetooth devices
    for (final btDevice in _bluetoothService.discoveredDevices) {
      devices.add(ProximityDevice(
        id: btDevice.id,
        name: '${btDevice.displayName} (Bluetooth)',
        mode: ShareMode.bluetooth,
        isAvailable: btDevice.isAvailable,
      ));
    }

    // Add WiFi Direct devices (if hotspot is active)
    if (_wifiService.hotspotConfig != null) {
      final config = _wifiService.hotspotConfig!;
      devices.add(ProximityDevice(
        id: 'wifi_${config.ssid}',
        name: '${config.ssid} (WiFi)',
        mode: ShareMode.wifiDirect,
        isAvailable: true,
      ));
    }

    _devicesController.add(devices);
  }

  /// Get sharing statistics
  Map<String, dynamic> getStatistics() {
    return {
      'bluetooth_devices': _bluetoothService.discoveredDevices.length,
      'bluetooth_connected': _bluetoothService.discoveredDevices
          .where((d) => d.isConnected)
          .length,
      'wifi_active': _wifiService.hotspotConfig != null,
      'wifi_ssid': _wifiService.hotspotConfig?.ssid,
      'preferred_mode': _preferredMode.toString(),
      'current_state': _currentState.toString(),
    };
  }

  /// Update state
  void _updateState(ProximityShareState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Stop all services
  Future<void> stop() async {
    await Future.wait([
      _bluetoothService.stop(),
      _wifiService.stop(),
    ]);
    _updateState(ProximityShareState.idle);
  }

  /// Dispose resources
  void dispose() {
    stop();
    _bluetoothService.dispose();
    _wifiService.dispose();
    _stateController.close();
    _devicesController.close();
    _receivedNotesController.close();
    _errorController.close();
  }
}
