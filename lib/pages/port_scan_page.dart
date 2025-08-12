import 'dart:async';
import 'package:flutter/material.dart';
import '../services/port_scan_service.dart';
import '../widgets/app_scaffold.dart';

class PortScanPage extends StatefulWidget {
  const PortScanPage({super.key});

  @override
  State<PortScanPage> createState() => _PortScanPageState();
}

class _PortScanPageState extends State<PortScanPage> {
  final TextEditingController hostController = TextEditingController(text: '127.0.0.1');
  final TextEditingController startPortController = TextEditingController(text: '1');
  final TextEditingController endPortController = TextEditingController(text: '1024');
  final TextEditingController filterController = TextEditingController();

  bool running = false;
  StreamSubscription<PortScanUpdate>? sub;
  PortScanProcess? procRef;
  final List<PortScanUpdate> results = <PortScanUpdate>[];

  @override
  void dispose() {
    sub?.cancel();
    hostController.dispose();
    startPortController.dispose();
    endPortController.dispose();
    filterController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final host = hostController.text.trim();
    final startPort = int.tryParse(startPortController.text) ?? 1;
    final endPort = int.tryParse(endPortController.text) ?? 1024;
    if (host.isEmpty) return;

    setState(() {
      results.clear();
      running = true;
    });

    final svc = PortScanService();
    final proc = await svc.start(
      host: host,
      startPort: startPort,
      endPort: endPort,
      timeout: const Duration(milliseconds: 400),
      concurrency: 256,
    );
    procRef = proc;

    sub = proc.stream.listen((u) {
      setState(() {
        // Replace existing entry for the port, else insert sorted
        final idx = results.indexWhere((r) => r.port == u.port);
        if (idx >= 0) {
          results[idx] = u;
        } else {
          results.add(u);
          results.sort((a, b) => a.port.compareTo(b.port));
        }
      });
    }, onDone: () {
      setState(() => running = false);
    });
  }

  Future<void> _stop() async {
    await procRef?.cancel();
    await sub?.cancel();
    setState(() {
      running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = filterController.text.trim().toLowerCase();
    final filtered = filter.isEmpty
        ? results
        : results.where((r) {
            final service = r.serviceName?.toLowerCase() ?? '';
            return r.port.toString().contains(filter) || service.contains(filter);
          }).toList();

    final openPorts = filtered.where((r) => r.isOpen).toList();

    return AppScaffold(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Port Scanner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host (e.g., 127.0.0.1)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: startPortController,
                    decoration: const InputDecoration(
                      labelText: 'Start Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: endPortController,
                    decoration: const InputDecoration(
                      labelText: 'End Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: running ? null : _start,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: running ? _stop : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: filterController,
                    decoration: const InputDecoration(
                      labelText: 'Filter (port or service)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Open: ${openPorts.where((e) => e.isOpen).length}/${filtered.length}')
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: filtered.isEmpty
                    ? const Center(child: Text('No results yet. Start a scan.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final r = filtered[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              r.isOpen ? Icons.lock_open : Icons.lock_outline,
                              color: r.isOpen ? Colors.green : Colors.grey,
                              size: 18,
                            ),
                            title: Text('Port ${r.port}${r.serviceName != null ? ' (${r.serviceName})' : ''}'),
                            trailing: Text(
                              r.isOpen ? 'OPEN' : 'closed',
                              style: TextStyle(
                                color: r.isOpen ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}