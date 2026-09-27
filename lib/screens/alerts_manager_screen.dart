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
          content: Text(_milkReminders ? 'Reminders scheduled! ✅' : 'Reminders disabled.'),
          backgroundColor: _milkReminders ? Colors.green : Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: GlobalDrawer(currentIndex: 4, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: const Text('Farm Alerts & Reminders'),
        
        elevation: 0,
        
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppConstants.primaryColor,
          tabs: const [
             Tab(icon: Icon(Icons.notifications_active), text: 'Upcoming'),
             Tab(icon: Icon(Icons.settings), text: 'Settings'),
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
    if (_isLoading) return const PremiumLoading(message: 'Checking for upcoming events...');
    if (_upcomingBreedingAlerts.isEmpty) {
      return const Center(child: Text('No upcoming alerts scheduled.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalvingAlertsScreen(onMenuPressed: widget.onMenuPressed))),
            icon: const Icon(Icons.child_care),
            label: const Text('View Detailed Maternity Calendar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent.withOpacity(0.1),
              foregroundColor: Colors.pinkAccent,
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
      itemCount: _upcomingBreedingAlerts.length,
      itemBuilder: (context, index) {
        final alert = _upcomingBreedingAlerts[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.notification_important, color: Colors.white)),
            title: Text('Cow ${alert['tag']} - ${alert['event']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Alert on: ${DateFormat('MMM d, y').format(alert['date'])}'),
            trailing: const Icon(Icons.chevron_right, size: 16),
          ),
        );
      },
    ),
  ),
],
);
}

  Widget _buildSettingsTab(LanguageProvider lp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Milk Shift Reminders'),
            subtitle: const Text('Remind me to enter milk data daily'),
            value: _milkReminders, 
            activeColor: AppConstants.primaryColor,
            onChanged: (val) => setState(() => _milkReminders = val),
          ),
          const Divider(),
          ListTile(
            title: const Text('Morning Shift Time'),
            trailing: Text(_morningTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _morningTime);
              if (picked != null) setState(() => _morningTime = picked);
            },
          ),
          ListTile(
            title: const Text('Evening Shift Time'),
            trailing: Text(_eveningTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _eveningTime);
              if (picked != null) setState(() => _eveningTime = picked);
            },
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Advanced Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.shade100)),
            child: ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.blue),
              title: const Text('Send Test Notification', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tap to check if notifications work on your device'),
              onTap: () async {
                await NotificationService.showInstantTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Notification Sent!')));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
