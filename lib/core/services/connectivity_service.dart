import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _statusController = StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    if (results.isNotEmpty) {
      _updateStatus(results.first);
    }

    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateStatus(results.first);
      }
    });
  }

  void _updateStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      _statusController.add(ConnectivityStatus.offline);
    } else {
      _statusController.add(ConnectivityStatus.online);
    }
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _statusController.close();
  }
}
