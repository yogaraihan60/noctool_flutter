import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'services/ping_service.dart';
import 'state/tabs.dart';
import 'widgets/app_scaffold.dart';
import 'pages/traceroute_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NoctoolfApp());
}

class NoctoolfApp extends StatelessWidget {
  const NoctoolfApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/ping',
          builder: (context, state) => const PingPage(),
        ),
        GoRoute(
          path: '/traceroute',
          builder: (context, state) => const TraceroutePage(),
        ),
      ],
    );

    return ChangeNotifierProvider(
      create: (_) => TabsController(),
      child: MaterialApp.router(
        title: 'NOCTOOLF',
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        routerConfig: router,
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      child: Center(
        child: Text('Dashboard'),
      ),
    );
  }
}

class PingPage extends StatefulWidget {
  const PingPage({super.key});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
  final TextEditingController hostController = TextEditingController(text: '8.8.8.8');
  bool running = false;
  final List<_PingRow> rows = [];
  int seq = 0;
  StreamSubscription? sub;

  @override
  void dispose() {
    sub?.cancel();
    hostController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      rows.clear();
      running = true;
      seq = 0;
    });
    // Use system ping via PingService
    final host = hostController.text.trim();
    if (host.isEmpty) return;
    final svc = PingService();
    final proc = await svc.start(host: host, count: 999999, interval: const Duration(seconds: 1), timeout: const Duration(seconds: 2));
    sub = proc.stream.listen((u) {
      setState(() {
        seq = u.seq;
        rows.add(_PingRow(seq: u.seq, timeMs: u.timeMs ?? 0, ttl: u.ttl, timestamp: u.timestamp));
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
            const Text('Ping Tool', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: hostController,
                    decoration: const InputDecoration(labelText: 'Host (e.g., 8.8.8.8)'),
                  ),
                ),
                const SizedBox(width: 8),
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
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = rows[index];
                    return ListTile(
                      dense: true,
                      title: Text('seq ${r.seq}  time ${r.timeMs.toStringAsFixed(1)} ms  ttl ${r.ttl ?? '-'}'),
                      subtitle: Text(r.timestamp.toIso8601String()),
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

class _PingRow {
  final int seq;
  final double timeMs;
  final int? ttl;
  final DateTime timestamp;
  _PingRow({required this.seq, required this.timeMs, required this.ttl, required this.timestamp});
}
