import 'dart:io';

class DnsLookupResult {
  final String host;
  final List<InternetAddress> addresses;
  DnsLookupResult({required this.host, required this.addresses});
}

class DnsLookupService {
  Future<DnsLookupResult> lookup(String host) async {
    final addresses = await InternetAddress.lookup(host);
    return DnsLookupResult(host: host, addresses: addresses);
  }
}
