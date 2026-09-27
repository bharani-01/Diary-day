import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';
import '../models/health_record.dart';
import '../widgets/error_dialog.dart';
import '../services/database_service.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String cowId;

  const AddHealthRecordScreen({super.key, required this.cowId});

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  
  String _treatment = '';
  String _type = 'Treatment';
  String? _administeredBy;
  String? _notes;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _types = ['Vaccination', 'Treatment', 'Routine Checkup', 'Injury', 'Other'];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final record = HealthRecord(
        id: '', // Supabase will generate ID
        cowId: widget.cowId,
        treatment: _treatment,
        date: _selectedDate,
        type: _type,
        administeredBy: _administeredBy,
        notes: _notes,
      );
      
      await _db.addHealthRecord(record);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Add Medical Record')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Medical event', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Record Type', border: OutlineInputBorder()),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Treatment / Vaccine Name', hintText: 'e.g. FMD Vaccine, Antibiotic', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter treatment name' : null,
                      onSaved: (v) => _treatment = v!,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Administered By', hintText: 'Doctor Name or "Self"', border: OutlineInputBorder()),
                      onSaved: (v) => _administeredBy = v,
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius), side: BorderSide(color: Theme.of(context).dividerColor)),
                      title: const Text('Date of Treatment'),
                      subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, 
                          initialDate: _selectedDate, 
                          firstDate: DateTime(2020), 
                          lastDate: DateTime.now()
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes / Observations', border: OutlineInputBorder()),
                      onSaved: (v) => _notes = v,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: primaryButtonStyle(),
                        child: const Text('Save medical record'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
