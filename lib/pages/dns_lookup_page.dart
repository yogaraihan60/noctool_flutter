import 'dart:io';
import 'package:flutter/material.dart';
import '../services/dns_lookup_service.dart';
import '../widgets/app_scaffold.dart';

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
