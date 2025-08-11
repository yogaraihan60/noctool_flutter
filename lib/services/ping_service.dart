import 'dart:async';
import 'dart:convert';
import 'dart:io';

class PingUpdate {
  final int seq;
  final double? timeMs;
  final int? ttl;
  final DateTime timestamp;
  PingUpdate({required this.seq, required this.timeMs, required this.ttl, required this.timestamp});
}

class PingProcess {
  final Process _proc;
  final StreamController<PingUpdate> _controller = StreamController<PingUpdate>.broadcast();
  int _seq = 0;

  PingProcess._(this._proc) {
    _proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(_onLine, onDone: _controller.close);
    _proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((_) {}, onDone: () {});
  }

  Stream<PingUpdate> get stream => _controller.stream;

  void _onLine(String line) {
    final now = DateTime.now();
    // Common formats:
    // icmp_seq=1 ttl=57 time=10.3 ms
    // Reply from 8.8.8.8: bytes=32 time=14ms TTL=117
    double? timeMs;
    int? ttl;

    final timeMatch = RegExp(r'time[=<]?\s*(\d+(?:\.\d+)?)\s*ms', caseSensitive: false).firstMatch(line);
    if (timeMatch != null) {
      timeMs = double.tryParse(timeMatch.group(1)!);
    } else {
      final timeNoSpace = RegExp(r'time[=<]?(\d+(?:\.\d+)?)ms', caseSensitive: false).firstMatch(line);
      if (timeNoSpace != null) timeMs = double.tryParse(timeNoSpace.group(1)!);
    }

    final ttlMatch = RegExp(r'ttl[=:\s]+(\d+)', caseSensitive: false).firstMatch(line);
    if (ttlMatch != null) ttl = int.tryParse(ttlMatch.group(1)!);

    if (timeMs != null || ttl != null) {
      _seq += 1;
      _controller.add(PingUpdate(seq: _seq, timeMs: timeMs, ttl: ttl, timestamp: now));
    }
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

class PingService {
  Future<PingProcess> start({required String host, int count = 4, Duration interval = const Duration(seconds: 1), Duration timeout = const Duration(seconds: 2)}) async {
    if (Platform.isWindows) {
      final args = <String>['-n', '$count', '-w', '${timeout.inMilliseconds}', host];
      final proc = await Process.start('ping', args, runInShell: true);
      return PingProcess._(proc);
    } else if (Platform.isMacOS) {
      // macOS: -c <count>, -i <seconds>, -W <ms> (BSD ping)
      final args = <String>['-n', '-c', '$count', '-i', interval.inSeconds.toString(), '-W', '${timeout.inMilliseconds}', host];
      final proc = await Process.start('ping', args);
      return PingProcess._(proc);
    } else {
      // Linux: -c <count>, -i <seconds>, -W <seconds>
      final args = <String>['-n', '-c', '$count', '-i', interval.inSeconds.toString(), '-W', '${timeout.inSeconds}', host];
      final proc = await Process.start('ping', args);
      return PingProcess._(proc);
    }
  }
}

