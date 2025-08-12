import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../state/tabs.dart';
import '../state/tool_state.dart';
import '../state/theme.dart';
import '../state/tool_state.dart';
import 'tab_bar.dart';

class NewTabIntent extends Intent {
  const NewTabIntent();
}

class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

class NextTabIntent extends Intent {
  const NextTabIntent();
}

class PrevTabIntent extends Intent {
  const PrevTabIntent();
}

class AppScaffold extends StatelessWidget {
  final Widget child;
  
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyT, control: true): NewTabIntent(),
          SingleActivator(LogicalKeyboardKey.keyW, control: true): CloseTabIntent(),
          SingleActivator(LogicalKeyboardKey.tab, control: true): NextTabIntent(),
          SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true): PrevTabIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            NewTabIntent: CallbackAction<NewTabIntent>(
              onInvoke: (intent) {
                final tabs = context.read<TabsController>();
                final path = GoRouterState.of(context).uri.toString();
                final title = _titleForPath(path);
                final t = tabs.addTab(title, path);
                context.go(t.route);
                return null;
              },
            ),
            CloseTabIntent: CallbackAction<CloseTabIntent>(
              onInvoke: (intent) {
                final tabs = context.read<TabsController>();
                final activeId = tabs.activeId;
                if (activeId == null) return null;
                context.read<ToolStateStore>().clearTab(activeId);
                tabs.closeTab(activeId);
                context.go(tabs.active?.route ?? '/dashboard');
                return null;
              },
            ),
            NextTabIntent: CallbackAction<NextTabIntent>(
              onInvoke: (intent) {
                final tabs = context.read<TabsController>();
                final all = tabs.tabs;
                if (all.isEmpty) return null;
                final idx = all.indexWhere((t) => t.id == tabs.activeId);
                final next = all[(idx + 1) % all.length];
                tabs.setActive(next.id);
                context.go(next.route);
                return null;
              },
            ),
            PrevTabIntent: CallbackAction<PrevTabIntent>(
              onInvoke: (intent) {
                final tabs = context.read<TabsController>();
                final all = tabs.tabs;
                if (all.isEmpty) return null;
                final idx = all.indexWhere((t) => t.id == tabs.activeId);
                final prev = all[(idx - 1 + all.length) % all.length];
                tabs.setActive(prev.id);
                context.go(prev.route);
                return null;
              },
            ),
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('NOCTOOLF'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.brightness_6_outlined),
                  tooltip: 'Toggle theme',
                  onPressed: () {
                    final theme = context.read<ThemeController>();
                    theme.toggle();
                  },
                ),
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
                            final t = tabs.openOrActivate('Dashboard', '/dashboard');
                            context.go(t.route);
                          }
                          if (idx == 1) {
                            final t = tabs.openOrActivate('Ping', '/ping');
                            context.go(t.route);
                          }
                          if (idx == 2) {
                            final t = tabs.openOrActivate('Traceroute', '/traceroute');
                            context.go(t.route);
                          }
                          if (idx == 3) {
                            final t = tabs.openOrActivate('DNS Lookup', '/dns');
                            context.go(t.route);
                          }
                          if (idx == 4) {
                            final t = tabs.openOrActivate('Port Scan', '/port-scan');
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
          ),
        ),
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

  String _titleForPath(String path) {
    if (path.startsWith('/ping')) return 'Ping';
    if (path.startsWith('/traceroute')) return 'Traceroute';
    if (path.startsWith('/dns')) return 'DNS Lookup';
    if (path.startsWith('/port-scan')) return 'Port Scan';
    if (path.startsWith('/dashboard')) return 'Dashboard';
    return 'Tab';
  }
}


