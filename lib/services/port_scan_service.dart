import 'dart:async';
import 'dart:io';

class PortScanUpdate {
  final int port;
  final bool isOpen;
  final DateTime timestamp;
  final String? serviceName;

  PortScanUpdate({
    required this.port,
    required this.isOpen,
    required this.timestamp,
    this.serviceName,
  });
}

class PortScanProcess {
  final StreamController<PortScanUpdate> _controller = StreamController<PortScanUpdate>.broadcast();
  bool _isCancelled = false;

  Stream<PortScanUpdate> get stream => _controller.stream;

  Future<void> cancel() async {
    _isCancelled = true;
  }

  void _emit(PortScanUpdate update) {
    if (!_controller.isClosed) {
      _controller.add(update);
    }
  }

  Future<void> _scanPort({required String host, required int port, required Duration timeout}) async {
    if (_isCancelled) return;
    final now = DateTime.now();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      _emit(PortScanUpdate(port: port, isOpen: true, timestamp: now, serviceName: _wellKnownService(port)));
    } catch (_) {
      _emit(PortScanUpdate(port: port, isOpen: false, timestamp: now, serviceName: _wellKnownService(port)));
    }
  }

  Future<void> _run({
    required String host,
    required int startPort,
    required int endPort,
    required Duration timeout,
    required int concurrency,
  }) async {
    final int safeStart = startPort.clamp(1, 65535);
    final int safeEnd = endPort.clamp(1, 65535);
    if (safeEnd < safeStart) {
      for (int p = safeEnd; p <= safeStart; p++) {
        if (_isCancelled) break;
        await _scanPort(host: host, port: p, timeout: timeout);
      }
      await _controller.close();
      return;
    }

    // Chunked concurrency control
    const int minChunk = 8;
    final int chunkSize = concurrency.clamp(minChunk, 1024);

    int current = safeStart;
    while (current <= safeEnd && !_isCancelled) {
      final int batchEnd = (current + chunkSize - 1).clamp(safeStart, safeEnd);
      final List<Future<void>> futures = <Future<void>>[];
      for (int p = current; p <= batchEnd; p++) {
        if (_isCancelled) break;
        futures.add(_scanPort(host: host, port: p, timeout: timeout));
      }
      await Future.wait(futures);
      current = batchEnd + 1;
    }

    await _controller.close();
  }
}

class PortScanService {
  Future<PortScanProcess> start({
    required String host,
    int startPort = 1,
    int endPort = 1024,
    Duration timeout = const Duration(milliseconds: 400),
    int concurrency = 128,
  }) async {
    final proc = PortScanProcess();
    // Kick off the scan asynchronously; return the process immediately
    // ignore: unawaited_futures
    proc._run(
      host: host,
      startPort: startPort,
      endPort: endPort,
      timeout: timeout,
      concurrency: concurrency,
    );
    return proc;
  }
}

String? _wellKnownService(int port) {
  switch (port) {
    case 20:
    case 21:
      return 'FTP';
    case 22:
      return 'SSH';
    case 23:
      return 'Telnet';
    case 25:
      return 'SMTP';
    case 53:
      return 'DNS';
    case 80:
      return 'HTTP';
    case 110:
      return 'POP3';
    case 123:
      return 'NTP';
    case 143:
      return 'IMAP';
    case 161:
      return 'SNMP';
    case 389:
      return 'LDAP';
    case 443:
      return 'HTTPS';
    case 465:
      return 'SMTPS';
    case 587:
      return 'Mail (Submission)';
    case 993:
      return 'IMAPS';
    case 995:
      return 'POP3S';
    case 1433:
      return 'MSSQL';
    case 1521:
      return 'Oracle DB';
    case 2049:
      return 'NFS';
    case 2375:
      return 'Docker';
    case 3306:
      return 'MySQL';
    case 3389:
      return 'RDP';
    case 5432:
      return 'PostgreSQL';
    case 5672:
      return 'AMQP';
    case 5900:
      return 'VNC';
    case 6379:
      return 'Redis';
    case 8000:
    case 8080:
      return 'HTTP-alt';
    case 9200:
      return 'Elasticsearch';
    case 11211:
      return 'Memcached';
    default:
      return null;
  }
}