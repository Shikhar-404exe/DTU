

library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityState {
  online,
  offline,
  unknown,
}

enum NetworkType {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  other,
  none,
}

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  final _stateController = StreamController<ConnectivityState>.broadcast();
  final _typeController = StreamController<NetworkType>.broadcast();

  Stream<ConnectivityState> get stateStream => _stateController.stream;
  Stream<NetworkType> get typeStream => _typeController.stream;

  ConnectivityState _currentState = ConnectivityState.unknown;
  NetworkType _currentType = NetworkType.none;

  ConnectivityState get currentState => _currentState;
  NetworkType get currentType => _currentType;
  bool get isOnline => _currentState == ConnectivityState.online;
  bool get isOffline => _currentState == ConnectivityState.offline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> initialize() async {
    try {

      final results = await _connectivity.checkConnectivity();
      _updateState(results);

      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateState,
        onError: (error) {
          debugPrint('Connectivity error: $error');
          _currentState = ConnectivityState.unknown;
          _stateController.add(_currentState);
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize connectivity service: $e');
      _currentState = ConnectivityState.unknown;
    }
  }

  void _updateState(List<ConnectivityResult> results) {

    final hasConnection = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    final newState =
        hasConnection ? ConnectivityState.online : ConnectivityState.offline;

    NetworkType newType = NetworkType.none;
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          newType = NetworkType.wifi;
          break;
        case ConnectivityResult.mobile:
          newType = NetworkType.mobile;
          break;
        case ConnectivityResult.ethernet:
          newType = NetworkType.ethernet;
          break;
        case ConnectivityResult.vpn:
          newType = NetworkType.vpn;
          break;
        case ConnectivityResult.bluetooth:
          newType = NetworkType.bluetooth;
          break;
        case ConnectivityResult.other:
          newType = NetworkType.other;
          break;
        case ConnectivityResult.none:

          break;
      }

      if (newType == NetworkType.wifi || newType == NetworkType.mobile) {
        break;
      }
    }

    if (newState != _currentState) {
      _currentState = newState;
      _stateController.add(_currentState);
      debugPrint('Connectivity changed: $newState');
    }

    if (newType != _currentType) {
      _currentType = newType;
      _typeController.add(_currentType);
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateState(results);
      return isOnline;
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      return false;
    }
  }

  Future<T?> whenOnline<T>(
    Future<T> Function() callback, {
    T? fallback,
    void Function()? onOffline,
  }) async {
    if (isOnline) {
      return await callback();
    } else {
      onOffline?.call();
      return fallback;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
    _typeController.close();
  }
}
