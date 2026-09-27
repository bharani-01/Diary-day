import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/shift_milk_entry.dart';
import '../models/cow.dart';
import 'milk_entry_success_screen.dart';
import '../widgets/error_dialog.dart';

class MilkEntryScreen extends StatefulWidget {
  const MilkEntryScreen({super.key});
  @override
  State<MilkEntryScreen> createState() => _MilkEntryScreenState();
}

class _MilkEntryScreenState extends State<MilkEntryScreen> {
  final _db = DatabaseService();
  final _quantityController = TextEditingController();
  final _snfController = TextEditingController();
  final _fatController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = 'Morning';
  bool _isSaving = false;
  bool _isChecking = false;
  bool _isUpdate = false;
  bool _showEstimates = false;
  List<Cow> _milkingCows = [];
  Map<String, TextEditingController> _cowEstimateControllers = {};

  @override
  void initState() {
    super.initState();
    _autoDetectShift();
    _checkExistingEntry();
    _loadMilkingCows();
  }

  void _autoDetectShift() {
    final now = DateTime.now();
    _selectedShift = (now.hour >= 19 || now.hour < 7) ? 'Morning' : 'Evening';
  }

  Future<void> _loadMilkingCows() async {
    final cows = await _db.getCows();
    final milking = cows.where((c) => c.status == 'Active' && !c.isDry).toList();
    if (mounted) {
      setState(() {
        _milkingCows = milking;
        for (var cow in milking) {
          _cowEstimateControllers[cow.id] = TextEditingController();
        }
      });
      _loadExistingEstimates();
    }
  }

  Future<void> _loadExistingEstimates() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final estimates = await _db.getCowMilkEstimatesForShift(dateStr, _selectedShift);
      for (var entry in estimates.entries) {
        if (_cowEstimateControllers.containsKey(entry.key)) {
          _cowEstimateControllers[entry.key]!.text = entry.value.toString();
        }
      }
      if (estimates.isNotEmpty && mounted) setState(() => _showEstimates = true);
    } catch (_) {}
  }

  Future<void> _checkExistingEntry() async {
    setState(() => _isChecking = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final entry = await _db.getShiftMilkEntry(dateStr, _selectedShift);
      if (entry != null) {
        _quantityController.text = entry.quantity.toString();
        _snfController.text = entry.snf?.toString() ?? '';
        _fatController.text = entry.fatPercentage?.toString() ?? '';
        _isUpdate = true;
      } else {
        _quantityController.clear();
        _snfController.clear();
        _fatController.clear();
        _isUpdate = false;
      }
    } catch (e) {
      if (mounted) ErrorDialog.show(context, e);
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkExistingEntry();
      _loadExistingEstimates();
    }
  }

  Future<void> _save() async {
    if (_quantityController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final entry = ShiftMilkEntry(
        id: '',
        quantity: double.parse(_quantityController.text),
        entryDate: _selectedDate,
        shift: _selectedShift,
        snf: _snfController.text.isNotEmpty ? double.parse(_snfController.text) : null,
        fatPercentage: _fatController.text.isNotEmpty ? double.parse(_fatController.text) : null,
      );
      await _db.addShiftMilkEntry(entry);

      // Save per-cow estimates if any were entered
      if (_showEstimates) {
        Map<String, double> estimates = {};
        for (var cow in _milkingCows) {
          final ctrl = _cowEstimateControllers[cow.id];
          if (ctrl != null && ctrl.text.isNotEmpty) {
            final val = double.tryParse(ctrl.text);
            if (val != null && val > 0) estimates[cow.id] = val;
          }
        }
        if (estimates.isNotEmpty) {
          await _db.saveCowMilkEstimates(_selectedDate, _selectedShift, estimates);
        }
      }

      HapticFeedback.selectionClick();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MilkEntrySuccessScreen(quantity: entry.quantity, shift: entry.shift)));
      }
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); ErrorDialog.show(context, e); }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _snfController.dispose();
    _fatController.dispose();
    for (var c in _cowEstimateControllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Milk Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Collection Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Shift', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: ['Morning', 'Evening'].map((shift) {
                final isSelected = _selectedShift == shift;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(shift),
                    selected: isSelected,
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedShift = shift);
                      _checkExistingEntry();
                      _loadExistingEstimates();
                    },
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: isSelected ? AppConstants.primaryColor : Colors.black87),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Total Quantity (Liters)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_isChecking)
              const LinearProgressIndicator()
            else
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.0', suffixText: 'Liters',
                  helperText: _isUpdate ? 'Updating existing record for this shift' : 'Adding new record',
                  helperStyle: TextStyle(color: _isUpdate ? Colors.orange : Colors.grey),
                  border: const OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Fat (%)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: _fatController, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'e.g., 4.0', border: OutlineInputBorder())),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SNF', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: _snfController, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.done, decoration: const InputDecoration(hintText: 'e.g., 8.5', border: OutlineInputBorder())),
                ])),
              ],
            ),

            // --- Per-Cow Estimated Breakdown ---
            const SizedBox(height: 28),
            InkWell(
              onTap: () => setState(() => _showEstimates = !_showEstimates),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _showEstimates ? AppConstants.primaryColor.withOpacity(0.08) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _showEstimates ? AppConstants.primaryColor.withOpacity(0.3) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(_showEstimates ? Icons.expand_less : Icons.expand_more, color: AppConstants.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Per-Cow Estimates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Optional: estimate each cow\'s contribution', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ])),
                    Icon(Icons.science_outlined, color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),
            if (_showEstimates && _milkingCows.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: _milkingCows.map((cow) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text('${cow.tagNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                          if (cow.name != null)
                            Expanded(child: Text(cow.name!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), overflow: TextOverflow.ellipsis))
                          else
                            const Spacer(),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _cowEstimateControllers[cow.id],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: '0.0',
                                hintStyle: TextStyle(color: Colors.grey.shade300),
                                suffixText: 'L',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('💡 These are estimates and don\'t affect the total above', style: TextStyle(fontSize: 11, color: Theme.of(context).cardColor, fontStyle: FontStyle.italic)),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving || _isChecking ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                   ? const CircularProgressIndicator(color: Colors.white)
                   : Text(_isUpdate ? 'Update Entry' : 'Save Entry', style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
