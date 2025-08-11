import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TracerouteHop {
  final int hop;
  final String? ip;
  final String? hostname;
  final double? timeMs;
  final DateTime timestamp;
  final bool isTimeout;

  TracerouteHop({
    required this.hop,
    this.ip,
    this.hostname,
    this.timeMs,
    required this.timestamp,
    this.isTimeout = false,
  });
}

class TracerouteProcess {
  final Process _proc;
  final StreamController<TracerouteHop> _controller = StreamController<TracerouteHop>.broadcast();

  TracerouteProcess._(this._proc) {
    _proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(_onLine, onDone: _controller.close);
    _proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((_) {}, onDone: () {});
  }

  Stream<TracerouteHop> get stream => _controller.stream;

  void _onLine(String line) {
    final now = DateTime.now();
    
    // Common traceroute output formats:
    // Linux:  1  192.168.1.1  2.123 ms
    // macOS:  1  192.168.1.1  2.123 ms
    // Windows: 1     2 ms     3 ms     2 ms  192.168.1.1
    
    final hopMatch = RegExp(r'^\s*(\d+)\s+').firstMatch(line);
    if (hopMatch == null) return;
    
    final hop = int.tryParse(hopMatch.group(1)!) ?? 0;
    
    // Check for timeout
    if (line.contains('*') || line.contains('Request timed out')) {
      _controller.add(TracerouteHop(
        hop: hop,
        timestamp: now,
        isTimeout: true,
      ));
      return;
    }
    
    // Extract IP address
    final ipMatch = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(line);
    final ip = ipMatch?.group(1);
    
    // Extract time
    final timeMatch = RegExp(r'(\d+(?:\.\d+)?)\s*ms').firstMatch(line);
    final timeMs = timeMatch != null ? double.tryParse(timeMatch.group(1)!) : null;
    
    // Extract hostname (if present)
    String? hostname;
    if (ip != null) {
      final hostnameMatch = RegExp(r'([a-zA-Z0-9.-]+)\s+$').firstMatch(line);
      if (hostnameMatch != null) {
        hostname = hostnameMatch.group(1);
      }
    }
    
    _controller.add(TracerouteHop(
      hop: hop,
      ip: ip,
      hostname: hostname,
      timeMs: timeMs,
      timestamp: now,
    ));
  }

  Future<void> stop() async {
    try {
      _proc.kill(ProcessSignal.sigint);
    } catch (_) {
      _proc.kill();
    }
    await _proc.exitCode;
  }
}

class TracerouteService {
  Future<TracerouteProcess> start({
    required String host,
    int maxHops = 30,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (Platform.isWindows) {
      final args = <String>['-h', '$maxHops', '-w', '${timeout.inMilliseconds}', host];
      final proc = await Process.start('tracert', args, runInShell: true);
      return TracerouteProcess._(proc);
    } else {
      // Linux/macOS: -m <max_hops>, -w <timeout>
      final args = <String>['-m', '$maxHops', '-w', '${timeout.inSeconds}', host];
      final proc = await Process.start('traceroute', args);
      return TracerouteProcess._(proc);
    }
  }
}
