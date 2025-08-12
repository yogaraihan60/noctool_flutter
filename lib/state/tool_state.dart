import 'package:flutter/foundation.dart';

class ToolStateStore extends ChangeNotifier {
  final Map<String, Map<String, Object?>> _tabToToolToState = <String, Map<String, Object?>>{};

  T? getState<T>(String tabId, String toolKey) {
    final toolMap = _tabToToolToState[tabId];
    if (toolMap == null) return null;
    final value = toolMap[toolKey];
    if (value is T) return value;
    return null;
  }

  void setState(String tabId, String toolKey, Object? state) {
    final toolMap = _tabToToolToState.putIfAbsent(tabId, () => <String, Object?>{});
    toolMap[toolKey] = state;
    notifyListeners();
  }

  void clearTab(String tabId) {
    _tabToToolToState.remove(tabId);
    notifyListeners();
  }
}

class DnsLookupTabState {
  final String host;
  final List<String> addresses; // store as strings for portability
  final String? error;
  final bool loading;

  const DnsLookupTabState({
    required this.host,
    required this.addresses,
    required this.loading,
    this.error,
  });
}

class TracerouteTabState {
  final String host;
  final int maxHops;
  final List<TracerouteHopState> hops;

  const TracerouteTabState({
    required this.host,
    required this.maxHops,
    required this.hops,
  });
}

class TracerouteHopState {
  final int hop;
  final String? ip;
  final String? hostname;
  final double? timeMs;
  final bool isTimeout;

  const TracerouteHopState({
    required this.hop,
    this.ip,
    this.hostname,
    this.timeMs,
    this.isTimeout = false,
  });
}

class PortScanTabState {
  final String host;
  final int startPort;
  final int endPort;
  final String filter;
  final List<PortScanEntryState> results;

  const PortScanTabState({
    required this.host,
    required this.startPort,
    required this.endPort,
    required this.filter,
    required this.results,
  });
}

class PortScanEntryState {
  final int port;
  final bool isOpen;
  final String? serviceName;

  const PortScanEntryState({
    required this.port,
    required this.isOpen,
    this.serviceName,
  });
}