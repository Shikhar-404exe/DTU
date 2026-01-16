

library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/note.dart';
import 'bluetooth_share_service.dart';
import 'wifi_direct_share_service.dart';

enum ShareMode {
  bluetooth,
  wifiDirect,
  auto,
}

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

  void _setupListeners() {

    _bluetoothService.devicesStream.listen((devices) {
      _updateDevicesList();
    });

    _wifiService.receivedNotesStream.listen((note) {
      _receivedNotesController.add(note);
    });

    _bluetoothService.errorStream.listen((error) {
      _errorController.add('Bluetooth: $error');
    });

    _wifiService.errorStream.listen((error) {
      _errorController.add('WiFi: $error');
    });
  }

  Future<bool> initialize({ShareMode preferredMode = ShareMode.auto}) async {
    _updateState(ProximityShareState.initializing);
    _preferredMode = preferredMode;

    try {

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

  Future<bool> startSending() async {
    if (_currentState != ProximityShareState.ready) {
      return false;
    }

    _updateState(ProximityShareState.broadcasting);

    try {

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

  Future<bool> startReceiving() async {
    if (_currentState != ProximityShareState.ready) {
      return false;
    }

    _updateState(ProximityShareState.discovering);

    try {

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

  Future<void> sendNoteToAll(Note note) async {
    _updateState(ProximityShareState.transferring);

    try {
      debugPrint('📤 Sending note via proximity share: ${note.topic}');

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

  Future<bool> connectToDevice(ProximityDevice device) async {
    if (device.mode == ShareMode.bluetooth) {
      return await _bluetoothService.connectToDevice(device.id);
    } else if (device.mode == ShareMode.wifiDirect) {

      return true;
    }
    return false;
  }

  void _updateDevicesList() {
    final devices = <ProximityDevice>[];

    for (final btDevice in _bluetoothService.discoveredDevices) {
      devices.add(ProximityDevice(
        id: btDevice.id,
        name: '${btDevice.displayName} (Bluetooth)',
        mode: ShareMode.bluetooth,
        isAvailable: btDevice.isAvailable,
      ));
    }

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

  void _updateState(ProximityShareState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> stop() async {
    await Future.wait([
      _bluetoothService.stop(),
      _wifiService.stop(),
    ]);
    _updateState(ProximityShareState.idle);
  }

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
