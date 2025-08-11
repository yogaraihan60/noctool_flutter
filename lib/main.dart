import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      ],
    );

    return MaterialApp.router(
      title: 'NOCTOOLF',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    );
  }
}

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOCTOOLF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
            onPressed: () => context.go('/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.network_ping_outlined),
            tooltip: 'Ping',
            onPressed: () => context.go('/ping'),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.network_ping_outlined),
                label: Text('Ping'),
              ),
            ],
            selectedIndex: _selectedIndexForPath(GoRouterState.of(context).uri.toString()),
            onDestinationSelected: (idx) {
              if (idx == 0) context.go('/dashboard');
              if (idx == 1) context.go('/ping');
            },
            labelType: NavigationRailLabelType.all,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndexForPath(String path) {
    if (path.startsWith('/ping')) return 1;
    return 0;
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

  Future<void> _start() async {
    setState(() {
      rows.clear();
      running = true;
      seq = 0;
    });
    // Temporary stub: simulate ping output every second.
    _tick();
  }

  Future<void> _tick() async {
    if (!running) return;
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || !running) return;
    setState(() {
      seq += 1;
      rows.add(_PingRow(
        seq: seq,
        timeMs: 10 + (seq % 20).toDouble(),
        ttl: 64,
        timestamp: DateTime.now(),
      ));
    });
    _tick();
  }

  Future<void> _stop() async {
    setState(() {
      running = false;
    });
  }
}

class _PingRow {
  final int seq;
  final double timeMs;
  final int? ttl;
  final DateTime timestamp;
  _PingRow({required this.seq, required this.timeMs, required this.ttl, required this.timestamp});
}
