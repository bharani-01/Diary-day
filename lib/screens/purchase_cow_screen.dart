import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cow.dart';
import '../services/database_service.dart';
import '../constants.dart';

class PurchaseCowScreen extends StatefulWidget {
  const PurchaseCowScreen({super.key});

  @override
  State<PurchaseCowScreen> createState() => _PurchaseCowScreenState();
}

class _PurchaseCowScreenState extends State<PurchaseCowScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  final _tagController = TextEditingController();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _sourceController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedCowType = 'Cow';
  String _selectedHealth = 'Healthy';
  bool _isSaving = false;
  bool _isLoadingTag = true;

  @override
  void initState() {
    super.initState();
    _loadNextTag();
  }

  Future<void> _loadNextTag() async {
    final nextTag = await _db.getNextTagNumber();
    if (mounted) {
      setState(() {
        _tagController.text = nextTag;
        _isLoadingTag = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase New Cattle', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('This will register the animal and add the cost to your expenses.', style: TextStyle(fontSize: 12, color: Colors.green))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagController,
                decoration: AppConstants.inputDecoration('Tag Number').copyWith(
                  suffixIcon: _isLoadingTag ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
                ),
                validator: (val) => val!.isEmpty ? 'Enter tag number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _nameController, decoration: AppConstants.inputDecoration('Name (Optional)')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _selectedCowType,
                    decoration: AppConstants.inputDecoration('Type'),
                    items: ['Cow', 'Buffalo', 'Bull', 'Heifer', 'Calf'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _selectedCowType = val!),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    controller: _ageController, 
                    decoration: AppConstants.inputDecoration('Age (Years)'),
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _breedController, decoration: AppConstants.inputDecoration('Breed (e.g., Jersey, HF)')),
              
              const SizedBox(height: 32),
              const Text('Purchase Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourceController, 
                decoration: AppConstants.inputDecoration('Source / Seller Name'),
                validator: (val) => val!.isEmpty ? 'Enter source' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController, 
                decoration: AppConstants.inputDecoration('Purchase Price (₹)'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedHealth,
                decoration: AppConstants.inputDecoration('Health Condition at Arrival'),
                items: ['Healthy', 'Thin', 'Weak', 'Recently Treated'].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                onChanged: (val) => setState(() => _selectedHealth = val!),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final cow = Cow(
        id: '',
        tagNumber: _tagController.text,
        name: _nameController.text.isEmpty ? null : _nameController.text,
        breed: _breedController.text.isEmpty ? null : _breedController.text,
        age: int.tryParse(_ageController.text),
        healthStatus: _selectedHealth,
        cowType: _selectedCowType,
        createdAt: DateTime.now(),
      );

      await _db.purchaseCow(
        cow, 
        double.parse(_priceController.text), 
        _sourceController.text
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cattle Purchase Recorded!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
