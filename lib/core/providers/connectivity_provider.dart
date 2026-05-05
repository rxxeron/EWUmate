import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider that broadcasts true if the user is connected to the internet, else false.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  
  // Emit initial state
  final initialStatus = await connectivity.checkConnectivity();
  yield _isConnected(initialStatus);

  // Listen to changes
  await for (final status in connectivity.onConnectivityChanged) {
    yield _isConnected(status);
  }
});

bool _isConnected(List<ConnectivityResult> results) {
  // Return true if any result indicates a valid network connection
  return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn);
}
