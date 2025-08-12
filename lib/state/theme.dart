import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggle() {
    if (_mode == ThemeMode.light) {
      setMode(ThemeMode.dark);
    } else {
      setMode(ThemeMode.light);
    }
  }
}