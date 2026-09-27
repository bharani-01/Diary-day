import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cow.dart';
import '../services/database_service.dart';
import '../constants.dart';

class SellCowScreen extends StatefulWidget {
  const SellCowScreen({super.key});

  @override
  State<SellCowScreen> createState() => _SellCowScreenState();
}

class _SellCowScreenState extends State<SellCowScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  Cow? _selectedCow;
  final _buyerController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _saleDate = DateTime.now();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sell Cow', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: StreamBuilder<List<Cow>>(
        stream: _db.getCowsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final activeCows = snapshot.data!.where((c) => c.status == 'Active').toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Cow to Sell', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Cow>(
                    value: _selectedCow,
                    decoration: AppConstants.inputDecoration('Select Cow'),
                    items: activeCows.map((cow) => DropdownMenuItem(
                      value: cow,
                      child: Text('#${cow.tagNumber} ${cow.name ?? ""}'),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCow = val),
                    validator: (val) => val == null ? 'Please select a cow' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Buyer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerController,
                    decoration: AppConstants.inputDecoration('Buyer Name'),
                    validator: (val) => val!.isEmpty ? 'Enter buyer name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: AppConstants.inputDecoration('Sale Price (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Enter price' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sale Date'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(_saleDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _saleDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _saleDate = picked);
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _saveSale() async {
    if (!_formKey.currentState!.validate() || _selectedCow == null) return;

    setState(() => _isSaving = true);
    try {
      await _db.sellCow(
        _selectedCow!.id, 
        _buyerController.text, 
        double.parse(_priceController.text), 
        _saleDate
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cow marked as Sold!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
