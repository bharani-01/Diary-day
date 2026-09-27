import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/monthly_budget.dart';
import '../models/expense.dart';

class BudgetManagerScreen extends StatefulWidget {
  const BudgetManagerScreen({super.key});
  @override
  State<BudgetManagerScreen> createState() => _BudgetManagerScreenState();
}

class _BudgetManagerScreenState extends State<BudgetManagerScreen> {
  final _db = DatabaseService();
  final _now = DateTime.now();
  List<MonthlyBudget> _budgets = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;

  final List<String> _categories = ['Feed', 'Beer Pottu', 'Cotton Feed', 'Doctor Fees', 'Medicine', 'Equipment', 'Labor', 'Cattle Purchase', 'Transport', 'Electricity/Water', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await _db.getBudgetsForMonth(_now.month, _now.year);
      final expenses = await _db.getExpenses();
      setState(() {
        _budgets = budgets;
        _expenses = expenses.where((e) => e.expenseDate.month == _now.month && e.expenseDate.year == _now.year).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _getSpentForCategory(String category) {
    return _expenses.where((e) => e.category == category).fold(0.0, (sum, e) => sum + e.amount);
  }

  MonthlyBudget? _getBudgetForCategory(String category) {
    try { return _budgets.firstWhere((b) => b.category == category); } catch (_) { return null; }
  }

  void _showSetBudgetDialog(String category) {
    final existing = _getBudgetForCategory(category);
    final ctrl = TextEditingController(text: existing?.budgetAmount.toStringAsFixed(0) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set Budget: $category'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(prefixText: '₹ ', labelText: 'Monthly Budget', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              try {
                await _db.upsertBudget(MonthlyBudget(id: '', category: category, budgetAmount: double.parse(ctrl.text), month: _now.month, year: _now.year));
                if (mounted) { Navigator.pop(ctx); _loadData(); }
              } catch (e) {
                if (mounted) {
                  showDialog(context: ctx, builder: (_) => AlertDialog(title: const Text('Error'), content: Text(e.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(_now);
    final totalBudget = _budgets.fold(0.0, (sum, b) => sum + b.budgetAmount);
    final totalSpent = _expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Budget — $monthName', style: const TextStyle(fontWeight: FontWeight.bold)),   elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppConstants.primaryColor, Colors.teal.shade700]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('Budget', '₹${totalBudget.toStringAsFixed(0)}', Colors.white),
                        Container(width: 1, height: 40, color: Colors.white38),
                        _summaryItem('Spent', '₹${totalSpent.toStringAsFixed(0)}', totalSpent > totalBudget && totalBudget > 0 ? Colors.red.shade200 : Colors.white),
                        Container(width: 1, height: 40, color: Colors.white38),
                        _summaryItem('Left', '₹${(totalBudget - totalSpent).toStringAsFixed(0)}', (totalBudget - totalSpent) < 0 ? Colors.red.shade200 : Colors.greenAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Category wise
                  ..._categories.map((cat) {
                    final budget = _getBudgetForCategory(cat);
                    final spent = _getSpentForCategory(cat);
                    final budgetAmt = budget?.budgetAmount ?? 0;
                    final progress = budgetAmt > 0 ? (spent / budgetAmt).clamp(0.0, 1.5) : 0.0;
                    final isOverBudget = budgetAmt > 0 && spent > budgetAmt;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: isOverBudget ? Border.all(color: Colors.red.shade200) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: InkWell(
                        onTap: () => _showSetBudgetDialog(cat),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(budgetAmt > 0 ? '₹${spent.toStringAsFixed(0)} / ₹${budgetAmt.toStringAsFixed(0)}' : spent > 0 ? '₹${spent.toStringAsFixed(0)} spent' : 'Tap to set', style: TextStyle(fontSize: 12, color: isOverBudget ? Colors.red : Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Theme.of(context).dividerColor,
                                valueColor: AlwaysStoppedAnimation(isOverBudget ? Colors.red : progress > 0.8 ? Colors.orange : AppConstants.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
