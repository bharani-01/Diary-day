import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/notification_service.dart';
import '../services/language_provider.dart';
import '../services/database_service.dart';
import '../models/cow.dart';
import '../widgets/global_drawer.dart';
import 'calving_alerts_screen.dart';
import '../widgets/premium_loading.dart';
import '../widgets/app_ui.dart';

class AlertsManagerScreen extends StatefulWidget {
  final Function(int) onMenuPressed;
  const AlertsManagerScreen({super.key, required this.onMenuPressed});

  @override
  State<AlertsManagerScreen> createState() => _AlertsManagerScreenState();
}

class _AlertsManagerScreenState extends State<AlertsManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseService();
  
  bool _milkReminders = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 19, minute: 0);
  
  List<Map<String, dynamic>> _upcomingBreedingAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
    _loadUpcomingAlerts();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _milkReminders = prefs.getBool('milk_reminders') ?? true;
      _morningTime = TimeOfDay(
        hour: prefs.getInt('m_hour') ?? 7,
        minute: prefs.getInt('m_min') ?? 0,
      );
      _eveningTime = TimeOfDay(
        hour: prefs.getInt('e_hour') ?? 19,
        minute: prefs.getInt('e_min') ?? 0,
      );
    });
  }

  Future<void> _loadUpcomingAlerts() async {
    try {
      final cows = await _db.getCows();
      List<Map<String, dynamic>> alerts = [];
      
      for (var cow in cows) {
        final records = await _db.getBreedingRecordsForCow(cow.id);
        if (records.isNotEmpty) {
          final lastBreeding = records.first.breedingDate;
          final calvingDate = lastBreeding.add(const Duration(days: 283));
          final reminderDate = calvingDate.subtract(const Duration(days: 7));
          
          if (reminderDate.isAfter(DateTime.now())) {
            alerts.add({
              'tag': cow.tagNumber,
              'event': 'Calving Reminder',
              'date': reminderDate,
            });
          }
        }
      }
      setState(() {
        _upcomingBreedingAlerts = alerts..sort((a, b) => a['date'].compareTo(b['date']));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('milk_reminders', _milkReminders);
    await prefs.setInt('m_hour', _morningTime.hour);
    await prefs.setInt('m_min', _morningTime.minute);
    await prefs.setInt('e_hour', _eveningTime.hour);
    await prefs.setInt('e_min', _eveningTime.minute);

    if (_milkReminders) {
      await NotificationService.scheduleDailyShiftReminders(
        morningHour: _morningTime.hour,
        morningMin: _morningTime.minute,
        eveningHour: _eveningTime.hour,
        eveningMin: _eveningTime.minute,
      );
    } else {
      await NotificationService.cancelDailyReminders();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_milkReminders ? 'Reminders scheduled' : 'Reminders disabled'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      drawer: GlobalDrawer(currentIndex: 4, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: const Text('Alerts & reminders'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: context.mutedText,
          indicatorColor: AppConstants.primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
             Tab(text: 'Upcoming'),
             Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildSettingsTab(lp),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoading) return const PremiumLoading(message: 'Checking upcoming events…');
    if (_upcomingBreedingAlerts.isEmpty) {
      return const EmptyState(icon: Icons.notifications_none, title: 'No upcoming alerts scheduled');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingBreedingAlerts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalvingAlertsScreen(onMenuPressed: widget.onMenuPressed))),
              child: ListTile(
                leading: const IconTile(Icons.child_care, color: AppConstants.primaryColor),
                title: const Text('Calving calendar', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Expected deliveries with photos and dates', style: TextStyle(fontSize: 12, color: context.mutedText)),
                trailing: Icon(Icons.chevron_right, color: context.mutedText),
              ),
            ),
          );
        }
        final alert = _upcomingBreedingAlerts[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const IconTile(Icons.notifications_none, color: AppConstants.warningColor),
              title: Text('Cow ${alert['tag']} · ${alert['event']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Alert on ${DateFormat('MMM d, y').format(alert['date'])}', style: TextStyle(fontSize: 12, color: context.mutedText)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(LanguageProvider lp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Daily reminders'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Milk shift reminders'),
                  subtitle: Text('Remind me to enter milk data daily', style: TextStyle(fontSize: 12, color: context.mutedText)),
                  value: _milkReminders, 
                  activeColor: AppConstants.primaryColor,
                  onChanged: (val) => setState(() => _milkReminders = val),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Morning shift time'),
                  trailing: Text(_morningTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600, color: AppConstants.primaryColor)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _morningTime);
                    if (picked != null) setState(() => _morningTime = picked);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Evening shift time'),
                  trailing: Text(_eveningTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600, color: AppConstants.primaryColor)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _eveningTime);
                    if (picked != null) setState(() => _eveningTime = picked);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveSettings,
            style: primaryButtonStyle(),
            child: const Text('Apply changes'),
          ),
          const SizedBox(height: AppConstants.sectionGap),
          const SectionHeader('Troubleshooting'),
          AppCard(
            padding: EdgeInsets.zero,
            onTap: () async {
              await NotificationService.showInstantTestNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test notification sent')));
              }
            },
            child: ListTile(
              leading: const IconTile(Icons.notifications_active_outlined),
              title: const Text('Send test notification', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Check that notifications work on this device', style: TextStyle(fontSize: 12, color: context.mutedText)),
            ),
          ),
        ],
      ),
    );
  }
}

