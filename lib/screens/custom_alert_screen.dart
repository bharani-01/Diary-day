import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/custom_alert.dart';
import '../models/cow.dart';

class CustomAlertScreen extends StatefulWidget {
  const CustomAlertScreen({super.key});
  @override
  State<CustomAlertScreen> createState() => _CustomAlertScreenState();
}

class _CustomAlertScreenState extends State<CustomAlertScreen> {
  final _db = DatabaseService();

  void _showAddDialog() async {
    final cows = await _db.getCows();
    if (!mounted) return;
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selTime = const TimeOfDay(hour: 8, minute: 0);
    Cow? selCow;
    bool isRec = false;
    String freq = 'daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Create Reminder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title *', prefixIcon: const Icon(Icons.alarm), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).inputDecorationTheme.fillColor)),
              const SizedBox(height: 12),
              DropdownButtonFormField<Cow?>(
                value: selCow,
                decoration: InputDecoration(labelText: 'Link to Cow (optional)', prefixIcon: const Icon(Icons.pets), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).inputDecorationTheme.fillColor),
                items: [const DropdownMenuItem<Cow?>(value: null, child: Text('None')), ...cows.where((c) => c.status == 'Active').map((c) => DropdownMenuItem(value: c, child: Text('${c.tagNumber} ${c.name ?? ''}')))],
                onChanged: (v) => ss(() => selCow = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ss(() {
                          final newNow = DateTime.now().add(const Duration(minutes: 1));
                          selDate = newNow;
                          selTime = TimeOfDay(hour: newNow.hour, minute: newNow.minute);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('⚡ 1 Min'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ss(() {
                          final newNow = DateTime.now().add(const Duration(minutes: 10));
                          selDate = newNow;
                          selTime = TimeOfDay(hour: newNow.hour, minute: newNow.minute);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('⚡ 10 Min'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ss(() {
                          final newNow = DateTime.now().add(const Duration(hours: 1));
                          selDate = newNow;
                          selTime = TimeOfDay(hour: newNow.hour, minute: newNow.minute);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('⚡ 1 Hour'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12), tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
                leading: const Icon(Icons.calendar_today, color: AppConstants.primaryColor),
                title: const Text('Date'), trailing: Text(DateFormat('MMM d, y').format(selDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async { final p = await showDatePicker(context: ctx, initialDate: selDate, firstDate: DateTime.now(), lastDate: DateTime(2030)); if (p != null) ss(() => selDate = p); },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12), tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
                leading: const Icon(Icons.access_time, color: AppConstants.primaryColor),
                title: const Text('Time'), trailing: Text(selTime.format(ctx), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async { final p = await showTimePicker(context: ctx, initialTime: selTime); if (p != null) ss(() => selTime = p); },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  _getTimeRemainingText(selDate, selTime),
                  style: TextStyle(
                    fontSize: 13,
                    color: _getTimeRemainingText(selDate, selTime).contains('past') ? Colors.red : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12), tileColor: Theme.of(context).cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)), secondary: const Icon(Icons.repeat, color: Colors.orange), title: const Text('Recurring'), value: isRec, activeColor: AppConstants.primaryColor, onChanged: (v) => ss(() => isRec = v)),
              if (isRec) ...[const SizedBox(height: 12), SegmentedButton<String>(segments: const [ButtonSegment(value: 'daily', label: Text('Daily')), ButtonSegment(value: 'weekly', label: Text('Weekly')), ButtonSegment(value: 'monthly', label: Text('Monthly'))], selected: {freq}, onSelectionChanged: (v) => ss(() => freq = v.first))],
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, maxLines: 2, decoration: InputDecoration(labelText: 'Notes', prefixIcon: const Icon(Icons.note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Theme.of(context).inputDecorationTheme.fillColor)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  try {
                    final tStr = '${selTime.hour.toString().padLeft(2,'0')}:${selTime.minute.toString().padLeft(2,'0')}:00';
                    await _db.addCustomAlert(CustomAlert(id: '', cowId: selCow?.id, cowTag: selCow?.tagNumber, title: titleCtrl.text, alertDate: selDate, alertTime: tStr, isRecurring: isRec, frequency: isRec ? freq : null, notes: notesCtrl.text.isEmpty ? null : notesCtrl.text, createdAt: DateTime.now()));
                    final sched = DateTime(selDate.year, selDate.month, selDate.day, selTime.hour, selTime.minute);
                    if (sched.isAfter(DateTime.now())) { await NotificationService.scheduleNotification(id: titleCtrl.text.hashCode, title: '🔔 ${titleCtrl.text}', body: selCow != null ? 'Cow: ${selCow!.tagNumber}' : 'Farm Reminder', scheduledDate: sched); }
                    if (mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (mounted) {
                      showDialog(context: ctx, builder: (_) => AlertDialog(title: const Text('Error'), content: Text(e.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Create Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          )),
        ),
      ),
    );
  }

  String _getTimeRemainingText(DateTime date, TimeOfDay time) {
    final now = DateTime.now();
    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final diff = scheduled.difference(now);
    
    if (diff.isNegative) {
      return '⚠️ Selected time is in the past!';
    }
    
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    
    final List<String> parts = [];
    if (days > 0) parts.add('$days day${days > 1 ? "s" : ""}');
    if (hours > 0) parts.add('$hours hr${hours > 1 ? "s" : ""}');
    if (minutes > 0) parts.add('$minutes min${minutes > 1 ? "s" : ""}');
    
    if (parts.isEmpty) {
      return '🔔 Reminding in less than a minute!';
    }
    return '🔔 Reminding in ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Custom Reminders', style: TextStyle(fontWeight: FontWeight.bold)),   elevation: 0),
      body: StreamBuilder<List<CustomAlert>>(
        stream: _db.getCustomAlertsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final alerts = (snapshot.data ?? []).where((a) => !a.isDismissed).toList();
          if (alerts.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No active reminders', style: TextStyle(fontSize: 16, color: Theme.of(context).cardColor))]));
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: alerts.length,
            itemBuilder: (context, i) {
              final a = alerts[i];
              final overdue = a.alertDate.isBefore(DateTime.now());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: overdue ? Border.all(color: Colors.red.shade200) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(backgroundColor: overdue ? Colors.red.shade50 : Colors.orange.shade50, child: Icon(a.isRecurring ? Icons.repeat : Icons.alarm, color: overdue ? Colors.red : Colors.orange)),
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 4),
                    Text('${DateFormat('MMM d, y').format(a.alertDate)}${a.alertTime != null ? ' • ${a.alertTime!.substring(0,5)}' : ''}', style: TextStyle(fontSize: 12, color: overdue ? Colors.red : Colors.grey.shade600)),
                    if (a.cowTag != null) Text('🐄 ${a.cowTag}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    if (a.isRecurring) Text('🔄 ${a.frequency}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                  ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22), onPressed: () => _db.dismissCustomAlert(a.id)),
                    IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 22), onPressed: () => _db.deleteCustomAlert(a.id)),
                  ]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, backgroundColor: AppConstants.primaryColor, child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}
