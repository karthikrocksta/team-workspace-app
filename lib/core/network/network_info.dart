import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over connectivity so repositories can decide whether to hit
/// the remote data source or fall back to the local cache.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
