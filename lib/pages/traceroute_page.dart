import 'dart:async';
import 'package:flutter/material.dart';
import '../services/traceroute_service.dart';
import '../widgets/app_scaffold.dart';

class TraceroutePage extends StatefulWidget {
  const TraceroutePage({super.key});

  @override
  State<TraceroutePage> createState() => _TraceroutePageState();
}

class _TraceroutePageState extends State<TraceroutePage> {
  final TextEditingController hostController = TextEditingController(text: '8.8.8.8');
  final TextEditingController maxHopsController = TextEditingController(text: '30');
  bool running = false;
  final List<TracerouteHop> hops = [];
  StreamSubscription? sub;

  @override
  void dispose() {
    sub?.cancel();
    hostController.dispose();
    maxHopsController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final host = hostController.text.trim();
    if (host.isEmpty) return;
    
    final maxHops = int.tryParse(maxHopsController.text) ?? 30;
    
    setState(() {
      hops.clear();
      running = true;
    });

    final svc = TracerouteService();
    final proc = await svc.start(
      host: host,
      maxHops: maxHops,
      timeout: const Duration(seconds: 5),
    );
    
    sub = proc.stream.listen((hop) {
      setState(() {
        // Insert hop at correct position or update existing
        final existingIndex = hops.indexWhere((h) => h.hop == hop.hop);
        if (existingIndex >= 0) {
          hops[existingIndex] = hop;
        } else {
          hops.add(hop);
          // Sort by hop number
          hops.sort((a, b) => a.hop.compareTo(b.hop));
        }
      });
    });
  }

  Future<void> _stop() async {
    setState(() {
      running = false;
    });
    await sub?.cancel();
    sub = null;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traceroute Tool',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trace the network path to a destination host',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host (e.g., 8.8.8.8)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: maxHopsController,
                    decoration: const InputDecoration(
                      labelText: 'Max Hops',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
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
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: hops.isEmpty
                    ? const Center(
                        child: Text(
                          'No results yet. Click Start to begin tracing.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: hops.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final hop = hops[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: hop.isTimeout
                                  ? Colors.grey
                                  : hop.ip != null
                                      ? Colors.green
                                      : Colors.orange,
                              child: Text(
                                '${hop.hop}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              hop.isTimeout
                                  ? 'Request timed out'
                                  : hop.ip ?? 'Unknown',
                              style: TextStyle(
                                color: hop.isTimeout ? Colors.grey : null,
                              ),
                            ),
                            subtitle: hop.hostname != null
                                ? Text(hop.hostname!)
                                : null,
                            trailing: hop.timeMs != null
                                ? Text(
                                    '${hop.timeMs!.toStringAsFixed(1)} ms',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  )
                                : null,
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


