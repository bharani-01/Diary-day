import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/breeding_record.dart';

class AddBreedingRecordScreen extends StatefulWidget {
  final String cowId;
  const AddBreedingRecordScreen({super.key, required this.cowId});

  @override
  State<AddBreedingRecordScreen> createState() => _AddBreedingRecordScreenState();
}

class _AddBreedingRecordScreenState extends State<AddBreedingRecordScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final record = BreedingRecord(
        id: '', 
        cowId: widget.cowId,
        breedingDate: _selectedDate,
        details: _detailsController.text,
        createdAt: DateTime.now(),
      );

      await _db.addBreedingRecord(record);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Breeding Record')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.containerPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Breeding Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Estimated Delivery: ${DateFormat('MMM d, y').format(_selectedDate.add(const Duration(days: 283)))}',
                style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              const Text('Details (Injections, Bull info, etc.)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter details about injections or breeding process...',
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  filled: true,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Theme.of(context).cardColor, strokeWidth: 2))
                    : const Text('Save Record', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
