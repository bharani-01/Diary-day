import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';
import '../models/health_record.dart';
import '../models/cow.dart';
import '../services/database_service.dart';
import '../widgets/error_dialog.dart';

class GlobalAddHealthRecordScreen extends StatefulWidget {
  const GlobalAddHealthRecordScreen({super.key});

  @override
  State<GlobalAddHealthRecordScreen> createState() => _GlobalAddHealthRecordScreenState();
}

class _GlobalAddHealthRecordScreenState extends State<GlobalAddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  
  List<Cow> _cows = [];
  Cow? _selectedCow;
  
  String _treatment = '';
  String _type = 'Treatment';
  String? _administeredBy;
  String? _notes;
  DateTime _selectedDate = DateTime.now();
  
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _types = ['Vaccination', 'Treatment', 'Routine Checkup', 'Injury', 'Other'];

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
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDialog.show(context, e);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCow == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a cow & fill required details')));
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    try {
      final record = HealthRecord(
        id: '', 
        cowId: _selectedCow!.id,
        treatment: _treatment,
        date: _selectedDate,
        type: _type,
        administeredBy: _administeredBy,
        notes: _notes,
      );
      
      await _db.addHealthRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical record saved successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
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
                    
                    const Text('Medical event', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(labelText: 'Record Type', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Treatment / Vaccine Name', hintText: 'e.g. FMD Vaccine', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter treatment name' : null,
                      onSaved: (v) => _treatment = v!,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: InputDecoration(labelText: 'Administered By', hintText: 'Doctor Name or "Self"', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                      onSaved: (v) => _administeredBy = v,
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      tileColor: Theme.of(context).cardColor,
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
                      decoration: InputDecoration(labelText: 'Notes / Observations', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                      onSaved: (v) => _notes = v,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: primaryButtonStyle(),
                        child: _isSaving 
                          ? const ButtonSpinner() 
                          : const Text('Save medical record'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
