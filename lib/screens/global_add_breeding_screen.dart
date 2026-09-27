import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/cow.dart';
import '../models/breeding_record.dart';

class GlobalAddBreedingScreen extends StatefulWidget {
  const GlobalAddBreedingScreen({super.key});

  @override
  State<GlobalAddBreedingScreen> createState() => _GlobalAddBreedingScreenState();
}

class _GlobalAddBreedingScreenState extends State<GlobalAddBreedingScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController(text: 'Artificial Insemination / Breeding Injection');
  
  List<Cow> _cows = [];
  Cow? _selectedCow;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCows();
  }

  Future<void> _fetchCows() async {
    try {
      final cows = await _db.getCows();
      setState(() {
        _cows = cows;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCow == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a cow')));
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final breedingTime = _selectedDate;
      final record = BreedingRecord(
        id: '', 
        cowId: _selectedCow!.id,
        breedingDate: breedingTime,
        details: _detailsController.text,
        createdAt: DateTime.now(),
      );

      await _db.addBreedingRecord(record);

      // --- SCHEDULE NOTIFICATION ---
      // Calving is approx 283 days after breeding
      final calvingDate = breedingTime.add(const Duration(days: 283));
      final reminderDate = calvingDate.subtract(const Duration(days: 7));
      
      if (reminderDate.isAfter(DateTime.now())) {
        final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await NotificationService.scheduleNotification(
          id: notificationId,
          title: 'Upcoming calving alert',
          body: 'Cow ${_selectedCow!.tagNumber} is expected to deliver in 7 days!',
          scheduledDate: reminderDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Breeding recorded & reminder set!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictedDate = _selectedDate.add(const Duration(days: 283));

    return Scaffold(
      appBar: AppBar(title: const Text('Record Breeding Injection')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.containerPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Cow', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Cow>(
                    value: _selectedCow,
                    hint: const Text('Choose Cow by Tag Number'),
                    decoration: InputDecoration(border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                    items: _cows.map((c) => DropdownMenuItem(value: c, child: Text('${c.tagNumber} - ${c.name ?? "Unnamed"} (${c.breed ?? "Native"})'))).toList(),
                    onChanged: (val) => setState(() => _selectedCow = val),
                    validator: (val) => val == null ? 'Selection required' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('Breeding / injection date', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppConstants.controlRadius), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
                          Icon(Icons.calendar_today_outlined, size: 20, color: context.mutedText),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  AppCard(
                    child: Row(
                      children: [
                        const IconTile(Icons.event_available_outlined, color: AppConstants.primaryColor),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Predicted calving date', style: TextStyle(fontSize: 12, color: context.mutedText)),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMMM d, y').format(predictedDate),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'About ${predictedDate.difference(DateTime.now()).inDays} days from today',
                                style: TextStyle(fontSize: 12, color: context.mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Injection details', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    decoration: InputDecoration(border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: primaryButtonStyle(),
                    child: _isSaving ? const ButtonSpinner() : const Text('Save record'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
