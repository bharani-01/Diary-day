import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/payment.dart';
import '../widgets/app_ui.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Milk Sale (Private)';
  DateTime? _periodStart;
  DateTime? _periodEnd;
  bool _isSaving = false;

  final List<String> _categories = [
    'Milk Sale (Private)',
    'Aavin Payment',
    'Cow Sale',
    'Manure Sale',
    'Other Income'
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = _selectedCategory;
  }

  void _onCategoryChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedCategory = val;
      _titleController.text = val;
      
      // Auto-set Aavin periods if selected
      if (val == 'Aavin Payment') {
        _suggestPeriod();
      } else {
        _periodStart = null;
        _periodEnd = null;
      }
    });
  }

  void _suggestPeriod() {
    final now = DateTime.now();
    if (now.day <= 10) {
      _periodStart = DateTime(now.year, now.month, 1);
      _periodEnd = DateTime(now.year, now.month, 10);
    } else if (now.day <= 20) {
      _periodStart = DateTime(now.year, now.month, 11);
      _periodEnd = DateTime(now.year, now.month, 20);
    } else {
      _periodStart = DateTime(now.year, now.month, 21);
      _periodEnd = DateTime(now.year, now.month + 1, 0); // Last day of month
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

  Future<void> _pickPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _periodStart != null && _periodEnd != null 
          ? DateTimeRange(start: _periodStart!, end: _periodEnd!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _periodStart = picked.start;
        _periodEnd = picked.end;
        
        // Update title to be more descriptive for Aavin
        if (_selectedCategory == 'Aavin Payment') {
          final fmt = DateFormat('MMM d');
          _titleController.text = '$_selectedCategory (${fmt.format(_periodStart!)} - ${fmt.format(_periodEnd!)})';
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final payment = Payment(
        id: '', 
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        paymentDate: _selectedDate,
        description: _descController.text,
        category: _selectedCategory,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
      );

      await _db.addPayment(payment);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Add Payment Received')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.containerPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Payment category', style: TextStyle(fontWeight: FontWeight.w600)),
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
                decoration: InputDecoration(labelText: 'Title / Reference', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              if (_selectedCategory == 'Aavin Payment') ...[
                const Text('Billing period (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickPeriod,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppConstants.controlRadius), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_periodStart == null ? 'Select Period' : '${DateFormat('MMM d, y').format(_periodStart!)} — ${DateFormat('MMM d, y').format(_periodEnd!)}'),
                        const Icon(Icons.date_range, color: AppConstants.primaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount Received (₹)', border: OutlineInputBorder(), prefixText: '₹ ', fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius), side: BorderSide(color: Theme.of(context).dividerColor)),
                title: const Text('Received Date'),
                subtitle: Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'Notes / Description', border: OutlineInputBorder(), fillColor: Theme.of(context).inputDecorationTheme.fillColor, filled: true),
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: primaryButtonStyle(),
                child: _isSaving ? const ButtonSpinner() : const Text('Save payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
