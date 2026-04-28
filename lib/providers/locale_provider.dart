// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  bool _isMN = true;
  bool get isMN => _isMN;

  LocaleProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isMN = prefs.getBool('locale_mn') ?? true;
    notifyListeners();
  }

  Future<void> set(bool mn) async {
    if (_isMN == mn) return;
    _isMN = mn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locale_mn', mn);
  }

  Future<void> toggle() => set(!_isMN);

  // Shorthand translate helper — use for simple two-value strings
  String t(String mn, String en) => _isMN ? mn : en;
}
