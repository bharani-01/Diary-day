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
    'add_milk': {'icon': Icons.water_drop_outlined},
    'add_expense': {'icon': Icons.receipt_long_outlined},
    'breeding_inj': {'icon': Icons.biotech_outlined},
    'add_health_record': {'icon': Icons.medical_services_outlined},
    'alerts': {'icon': Icons.notifications_none},
    'add_cow': {'icon': Icons.add_circle_outline},
    'add_payment': {'icon': Icons.payments_outlined},
    'export_reports': {'icon': Icons.description_outlined},
    'farm_calendar': {'icon': Icons.calendar_month_outlined},
    'weather_forecast': {'icon': Icons.cloud_outlined},
    'sell_cow': {'icon': Icons.sell_outlined},
    'dry_cow': {'icon': Icons.pause_circle_outline},
    'todo_list': {'icon': Icons.checklist},
    'purchase_cow': {'icon': Icons.shopping_cart_outlined},
    'vet_contacts': {'icon': Icons.contact_phone_outlined},
    'custom_reminders': {'icon': Icons.alarm},
    'budget_manager': {'icon': Icons.account_balance_wallet_outlined},
  };
}
