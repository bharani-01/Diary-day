import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../services/language_provider.dart';
import '../screens/weather_screen.dart';
import '../screens/farm_calendar_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/calving_alerts_screen.dart';
import '../screens/vet_contacts_screen.dart';
import '../screens/custom_alert_screen.dart';
import '../screens/budget_manager_screen.dart';

class GlobalDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const GlobalDrawer({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppConstants.primaryColor, Colors.teal]),
            ),
            currentAccountPicture: CircleAvatar(
              
              child: Icon(Icons.pets, color: AppConstants.primaryColor, size: 40),
            ),
            accountName: const Text('KRB Dairy Farms', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(
              lp.isTamil ? 'பண்ணை மேலாண்மை' : 'Professional Farm Suite',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          _drawerTile(context, Icons.dashboard, 'Dashboard', 0),
          _drawerTile(context, Icons.water_drop, 'Milk Records', 1),
          _drawerTile(context, Icons.pets, 'My Cows', 2),
          _drawerTile(context, Icons.currency_rupee, 'Financials', 3),
          _drawerTile(context, Icons.notifications_active, 'Alerts Manager', 4),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.cyan),
            title: const Text('Weather & Forecast'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.child_care, color: Colors.pinkAccent),
            title: const Text('Maternity Alerts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => CalvingAlertsScreen(onMenuPressed: onTabSelected)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.deepPurple),
            title: const Text('Farm Calendar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmCalendarScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.teal),
            title: const Text('Vet Contacts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VetContactsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm, color: Colors.orange),
            title: const Text('Reminders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomAlertScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.indigo),
            title: const Text('Budget Manager'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetManagerScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blueGrey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: AppConstants.primaryColor),
            title: Text(lp.translate('tap_to_switch')),
            onTap: () {
              lp.toggleLanguage();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String title, int index) {
    bool isSelected = currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppConstants.primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppConstants.primaryColor : Colors.black87,
        ),
      ),
      onTap: () {
        onTabSelected(index);
        Navigator.pop(context);
      },
    );
  }
}
