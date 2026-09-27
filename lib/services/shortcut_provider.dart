import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShortcutProvider extends ChangeNotifier {
  List<String> _selectedShortcuts = ['add_milk', 'export_reports', 'add_expense', 'breeding_inj'];
  
  List<String> get selectedShortcuts => _selectedShortcuts;

  ShortcutProvider() {
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('selected_shortcuts');
    if (saved != null) {
      _selectedShortcuts = saved;
      notifyListeners();
    }
  }

  Future<void> updateShortcuts(List<String> newList) async {
    _selectedShortcuts = newList;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_shortcuts', newList);
    notifyListeners();
  }

  // All possible shortcuts
  static const Map<String, Map<String, dynamic>> allShortcuts = {
    'add_milk': {'icon': Icons.add_circle, 'color': Colors.blue},
    'add_expense': {'icon': Icons.remove_circle, 'color': Colors.red},
    'breeding_inj': {'icon': Icons.biotech, 'color': Colors.purple},
    'add_health_record': {'icon': Icons.medical_services, 'color': Colors.redAccent},
    'alerts': {'icon': Icons.notifications_active, 'color': Colors.orange},
    'add_cow': {'icon': Icons.add_business, 'color': Colors.green},
    'add_payment': {'icon': Icons.account_balance_outlined, 'color': Colors.indigo},
    'export_reports': {'icon': Icons.file_present, 'color': Colors.teal},
    'farm_calendar': {'icon': Icons.calendar_month, 'color': Colors.deepPurple},
    'weather_forecast': {'icon': Icons.cloud, 'color': Colors.cyan},
    'sell_cow': {'icon': Icons.monetization_on, 'color': Colors.red},
    'dry_cow': {'icon': Icons.pause_circle_filled, 'color': Colors.orange},
    'todo_list': {'icon': Icons.assignment, 'color': Colors.blue},
    'purchase_cow': {'icon': Icons.shopping_cart, 'color': Colors.green},
    'vet_contacts': {'icon': Icons.medical_services_outlined, 'color': Colors.teal},
    'custom_reminders': {'icon': Icons.alarm, 'color': Colors.orange},
    'budget_manager': {'icon': Icons.account_balance_wallet, 'color': Colors.indigo},
  };
}
