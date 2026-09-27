import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyProvider with ChangeNotifier {
  bool _hideBalances = false;
  bool get hideBalances => _hideBalances;

  PrivacyProvider() {
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    _hideBalances = prefs.getBool('hideBalances') ?? false;
    notifyListeners();
  }

  Future<void> togglePrivacy() async {
    _hideBalances = !_hideBalances;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideBalances', _hideBalances);
    notifyListeners();
  }
}
