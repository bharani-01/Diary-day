import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
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
          title: 'Upcoming Calving Alert 🐄',
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
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.containerPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Select Cow 🐄', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('Breeding / Injection Date 💉', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('Predicted Calving Date 📅', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMMM d, y').format(predictedDate),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'approx. ${predictedDate.difference(DateTime.now()).inDays} days from today',
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Injection Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    decoration: InputDecoration(border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Record', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
