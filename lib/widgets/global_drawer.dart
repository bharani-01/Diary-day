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
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withOpacity(0.6);

    return Drawer(
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.controlRadius),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: AppConstants.primaryColor, size: 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('KRB Dairy Farms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          lp.isTamil ? 'பண்ணை மேலாண்மை' : 'Farm management',
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerTile(context, Icons.dashboard_outlined, 'Dashboard', 0),
                  _drawerTile(context, Icons.water_drop_outlined, 'Milk Records', 1),
                  _drawerTile(context, Icons.pets_outlined, 'My Cows', 2),
                  _drawerTile(context, Icons.currency_rupee, 'Financials', 3),
                  _drawerTile(context, Icons.notifications_none, 'Alerts Manager', 4),
                  _groupLabel(context, 'Tools'),
                  _linkTile(context, Icons.cloud_outlined, 'Weather & Forecast', () => const WeatherScreen()),
                  _linkTile(context, Icons.child_care_outlined, 'Maternity Alerts', () => CalvingAlertsScreen(onMenuPressed: onTabSelected)),
                  _linkTile(context, Icons.calendar_month_outlined, 'Farm Calendar', () => const FarmCalendarScreen()),
                  _linkTile(context, Icons.medical_services_outlined, 'Vet Contacts', () => const VetContactsScreen()),
                  _linkTile(context, Icons.alarm, 'Reminders', () => const CustomAlertScreen()),
                  _linkTile(context, Icons.account_balance_wallet_outlined, 'Budget Manager', () => const BudgetManagerScreen()),
                  _linkTile(context, Icons.settings_outlined, 'Settings', () => const SettingsScreen()),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.translate, color: muted, size: 22),
              title: Text(lp.translate('tap_to_switch')),
              onTap: () {
                lp.toggleLanguage();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _groupLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _linkTile(BuildContext context, IconData icon, String title, Widget Function() builder) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
      },
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String title, int index) {
    final bool isSelected = currentIndex == index;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: AppConstants.primaryColor.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)),
        leading: Icon(icon, size: 22, color: isSelected ? AppConstants.primaryColor : onSurface.withOpacity(0.6)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppConstants.primaryColor : onSurface,
          ),
        ),
        onTap: () {
          onTabSelected(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
