import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/tabs.dart';
import 'tab_bar.dart';

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
          IconButton(
            icon: const Icon(Icons.compass_calibration_outlined),
            tooltip: 'Traceroute',
            onPressed: () => context.go('/traceroute'),
          ),
          IconButton(
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'DNS Lookup',
            onPressed: () => context.go('/dns'),
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Port Scan',
            onPressed: () => context.go('/port-scan'),
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<TabsController>(
            builder: (context, tabs, _) => TabsBar(controller: tabs),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
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
                    NavigationRailDestination(
                      icon: Icon(Icons.compass_calibration_outlined),
                      label: Text('Traceroute'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.dns_outlined),
                      label: Text('DNS Lookup'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shield_outlined),
                      label: Text('Port Scan'),
                    ),
                  ],
                  selectedIndex: _selectedIndexForPath(GoRouterState.of(context).uri.toString()),
                  onDestinationSelected: (idx) {
                    final tabs = context.read<TabsController>();
                    if (idx == 0) {
                      final t = tabs.addTab('Dashboard', '/dashboard');
                      context.go(t.route);
                    }
                    if (idx == 1) {
                      final t = tabs.addTab('Ping', '/ping');
                      context.go(t.route);
                    }
                    if (idx == 2) {
                      final t = tabs.addTab('Traceroute', '/traceroute');
                      context.go(t.route);
                    }
                    if (idx == 3) {
                      final t = tabs.addTab('DNS Lookup', '/dns');
                      context.go(t.route);
                    }
                    if (idx == 4) {
                      final t = tabs.addTab('Port Scan', '/port-scan');
                      context.go(t.route);
                    }
                  },
                  labelType: NavigationRailLabelType.all,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _selectedIndexForPath(String path) {
    if (path.startsWith('/ping')) return 1;
    if (path.startsWith('/traceroute')) return 2;
    if (path.startsWith('/dns')) return 3;
    if (path.startsWith('/port-scan')) return 4;
    return 0;
  }
}


