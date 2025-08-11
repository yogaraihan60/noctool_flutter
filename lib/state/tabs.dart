import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class TabItem {
  final String id;
  final String title;
  final String route;
  final DateTime createdAt;

  TabItem({required this.id, required this.title, required this.route, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  TabItem copyWith({String? title, String? route}) => TabItem(
        id: id,
        title: title ?? this.title,
        route: route ?? this.route,
        createdAt: createdAt,
      );
}

class TabsController extends ChangeNotifier {
  final List<TabItem> _tabs = <TabItem>[];
  String? _activeId;
  final _uuid = const Uuid();

  List<TabItem> get tabs => List.unmodifiable(_tabs);
  String? get activeId => _activeId;
  TabItem? get active => _tabs.where((t) => t.id == _activeId).cast<TabItem?>().firstOrNull;

  TabsController() {
    // Default tab
    final first = TabItem(id: _uuid.v4(), title: 'Dashboard', route: '/dashboard');
    _tabs.add(first);
    _activeId = first.id;
  }

  TabItem addTab(String title, String route) {
    final tab = TabItem(id: _uuid.v4(), title: title, route: route);
    _tabs.add(tab);
    _activeId = tab.id;
    notifyListeners();
    return tab;
  }

  void closeTab(String id) {
    final idx = _tabs.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final closingActive = _activeId == id;
    _tabs.removeAt(idx);
    if (_tabs.isEmpty) {
      final first = TabItem(id: _uuid.v4(), title: 'Dashboard', route: '/dashboard');
      _tabs.add(first);
      _activeId = first.id;
    } else if (closingActive) {
      final next = _tabs[idx < _tabs.length ? idx : _tabs.length - 1];
      _activeId = next.id;
    }
    notifyListeners();
  }

  void setActive(String id) {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }
}

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

