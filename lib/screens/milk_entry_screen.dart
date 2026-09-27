import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/shift_milk_entry.dart';
import '../models/cow.dart';
import 'milk_entry_success_screen.dart';
import '../widgets/error_dialog.dart';
import '../widgets/app_ui.dart';

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

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );

  @override
  Widget build(BuildContext context) {
    final muted = context.mutedText;
    return Scaffold(
      appBar: AppBar(title: Text(_isUpdate ? 'Edit milk entry' : 'New milk entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
                    trailing: Icon(Icons.chevron_right, color: muted),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 20),
                _fieldLabel('Shift'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Morning', label: Text('Morning'), icon: Icon(Icons.wb_twilight_outlined)),
                    ButtonSegment(value: 'Evening', label: Text('Evening'), icon: Icon(Icons.nights_stay_outlined)),
                  ],
                  selected: {_selectedShift},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedShift = s.first);
                    _checkExistingEntry();
                    _loadExistingEstimates();
                  },
                ),
                const SizedBox(height: 20),
                _fieldLabel('Total quantity'),
                if (_isChecking)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: LinearProgressIndicator())
                else
                  TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '0.0', suffixText: 'litres',
                      helperText: _isUpdate ? 'A record already exists for this shift. Saving will update it.' : 'New record for this shift',
                      helperStyle: TextStyle(color: _isUpdate ? AppConstants.warningColor : muted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Fat (%)'),
                      TextField(controller: _fatController, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, decoration: InputDecoration(hintText: 'e.g. 4.0', border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)))),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('SNF'),
                      TextField(controller: _snfController, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.done, decoration: InputDecoration(hintText: 'e.g. 8.5', border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius)))),
                    ])),
                  ],
                ),

                // --- Per-Cow Estimated Breakdown ---
                const SizedBox(height: 24),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => setState(() => _showEstimates = !_showEstimates),
                        title: const Text('Per-cow estimates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Optional. Does not change the total above.', style: TextStyle(fontSize: 12, color: muted)),
                        trailing: Icon(_showEstimates ? Icons.expand_less : Icons.expand_more, color: muted),
                      ),
                      if (_showEstimates && _milkingCows.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                                      Expanded(child: Text(cow.name!, style: TextStyle(fontSize: 12, color: muted), overflow: TextOverflow.ellipsis))
                                    else
                                      const Spacer(),
                                    SizedBox(
                                      width: 88,
                                      child: TextField(
                                        controller: _cowEstimateControllers[cow.id],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        decoration: InputDecoration(
                                          hintText: '0.0',
                                          hintStyle: TextStyle(color: context.subtleText),
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
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving || _isChecking ? null : _save,
                  style: primaryButtonStyle(),
                  child: _isSaving
                      ? const ButtonSpinner()
                      : Text(_isUpdate ? 'Update entry' : 'Save entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

