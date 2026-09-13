import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionService {
  ConnectionService({
    Connectivity? connectivity,
    Stream<List<ConnectivityResult>>? changes,
  })  : _connectivity = connectivity ?? Connectivity(),
        _changes = changes;

  final Connectivity _connectivity;
  final Stream<List<ConnectivityResult>>? _changes;

  Stream<bool> get isOnline => (_changes ?? _connectivity.onConnectivityChanged)
      .map((results) => !results.contains(ConnectivityResult.none))
      .distinct();
}
