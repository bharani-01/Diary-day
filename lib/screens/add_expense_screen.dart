import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/expense.dart';
import '../models/cow.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Feed';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isRecurring = false;
  String _frequency = 'monthly';
  Cow? _selectedCow;
  List<Cow> _activeCows = [];

  final List<String> _categories = [
    'Feed', 'Beer Pottu', 'Cotton Feed', 'Doctor Fees', 'Medicine',
    'Equipment', 'Labor', 'Cattle Purchase', 'Transport', 'Electricity/Water', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = _selectedCategory;
    _loadCows();
  }

  Future<void> _loadCows() async {
    final cows = await _db.getCows();
    if (mounted) setState(() => _activeCows = cows.where((c) => c.status == 'Active').toList());
  }

  void _onCategoryChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedCategory = val;
      if (_categories.contains(_titleController.text)) {
        _titleController.text = val;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final expense = Expense(
        id: '',
        title: _titleController.text,
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        expenseDate: _selectedDate,
        notes: _notesController.text,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
        cowId: _selectedCow?.id,
        cowTag: _selectedCow?.tagNumber,
      );
      await _db.addExpense(expense);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Add New Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.containerPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Expense Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title / Item Name', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount Spent (₹)', border: OutlineInputBorder(), prefixText: '₹ ', fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
                title: const Text('Expense Date'),
                subtitle: Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              // --- NEW: Link to Cow (Optional) ---
              DropdownButtonFormField<Cow?>(
                value: _selectedCow,
                decoration: InputDecoration(
                  labelText: 'Link to Cow (optional)',
                  prefixIcon: const Icon(Icons.pets),
                  border: const OutlineInputBorder(),
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true,
                  helperText: 'Track this expense against a specific cow',
                  helperStyle: TextStyle(color: Theme.of(context).cardColor, fontSize: 11),
                ),
                items: [
                  const DropdownMenuItem<Cow?>(value: null, child: Text('None — General Expense')),
                  ..._activeCows.map((c) => DropdownMenuItem(value: c, child: Text('${c.tagNumber} ${c.name ?? ''}'))),
                ],
                onChanged: (val) => setState(() => _selectedCow = val),
              ),
              const SizedBox(height: 16),
              // --- NEW: Recurring Toggle ---
              Container(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                child: SwitchListTile(
                  secondary: Icon(Icons.repeat, color: _isRecurring ? Colors.orange : Colors.grey),
                  title: const Text('Recurring Expense'),
                  subtitle: Text(_isRecurring ? 'Will auto-create ${_frequency}' : 'One-time expense', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  value: _isRecurring,
                  activeColor: AppConstants.primaryColor,
                  onChanged: (val) => setState(() => _isRecurring = val),
                ),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('Daily')),
                    ButtonSegment(value: 'weekly', label: Text('Weekly')),
                    ButtonSegment(value: 'monthly', label: Text('Monthly')),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (val) => setState(() => _frequency = val.first),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'Notes / Remarks', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Expense Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
