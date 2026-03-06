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
    try {
      final results = await _connectivity.checkConnectivity().timeout(
        const Duration(seconds: 2),
      );
      if (results.isNotEmpty) {
        _updateStatus(results.first);
      }
    } catch (e) {
      debugPrint("ConnectivityService: Init timeout or error $e");
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
    try {
      final result = await _connectivity.checkConnectivity().timeout(
        const Duration(seconds: 2),
      );
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _statusController.close();
  }
}
