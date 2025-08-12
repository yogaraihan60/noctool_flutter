import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dns_lookup_service.dart';
import '../widgets/app_scaffold.dart';
import '../state/tool_state.dart';
import '../state/tabs.dart';

class DnsLookupPage extends StatefulWidget {
  const DnsLookupPage({super.key});

  @override
  State<DnsLookupPage> createState() => _DnsLookupPageState();
}

class _DnsLookupPageState extends State<DnsLookupPage> {
  final TextEditingController hostController = TextEditingController(text: 'example.com');
  bool loading = false;
  List<InternetAddress> results = [];
  String? error;

  @override
  void initState() {
    super.initState();
    // Restore state if present
    final tabs = context.read<TabsController>();
    final tabId = tabs.activeId;
    if (tabId != null) {
      final store = context.read<ToolStateStore>();
      final saved = store.getState<DnsLookupTabState>(tabId, 'dns');
      if (saved != null) {
        hostController.text = saved.host;
        results = saved.addresses.map((e) => InternetAddress(e)).toList();
        loading = saved.loading;
        error = saved.error;
      }
    }
  }

  @override
  void dispose() {
    hostController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final host = hostController.text.trim();
    if (host.isEmpty) return;
    setState(() {
      loading = true;
      results = [];
      error = null;
    });
    try {
      final svc = DnsLookupService();
      final res = await svc.lookup(host);
      setState(() {
        results = res.addresses;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
    _persist();
  }

  void _persist() {
    final tabs = context.read<TabsController>();
    final tabId = tabs.activeId;
    if (tabId == null) return;
    final store = context.read<ToolStateStore>();
    store.setState(
      tabId,
      'dns',
      DnsLookupTabState(
        host: hostController.text.trim(),
        addresses: results.map((e) => e.address).toList(),
        loading: loading,
        error: error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DNS Lookup Tool', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: hostController,
                    decoration: const InputDecoration(labelText: 'Host (e.g., example.com)'),
                    onChanged: (_) => _persist(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: loading ? null : _lookup,
                  child: const Text('Lookup'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Builder(
                  builder: (context) {
                    if (loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (error != null) {
                      return Center(child: Text(error!, style: const TextStyle(color: Colors.red)));
                    }
                    if (results.isEmpty) {
                      return const Center(
                        child: Text('No results'),
                      );
                    }
                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final addr = results[index];
                        return ListTile(
                          dense: true,
                          title: Text(addr.address),
                          subtitle: Text(addr.type.name),
                        );
                      },
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
