import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/monthly_budget.dart';
import '../models/expense.dart';
import '../widgets/app_ui.dart';
import '../widgets/premium_loading.dart';

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
        title: Text('Budget for $category'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(prefixText: '₹ ', labelText: 'Monthly budget', border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.controlRadius))),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
      appBar: AppBar(title: Text('Budget · $monthName'), elevation: 0),
      body: _isLoading
          ? const PremiumLoading(message: 'Loading budget…')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                children: [
                  // Summary Card
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(child: _summaryItem('Budget', '₹${totalBudget.toStringAsFixed(0)}', Theme.of(context).colorScheme.onSurface)),
                          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                          Expanded(child: _summaryItem('Spent', '₹${totalSpent.toStringAsFixed(0)}', totalSpent > totalBudget && totalBudget > 0 ? AppConstants.dangerColor : Theme.of(context).colorScheme.onSurface)),
                          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                          Expanded(child: _summaryItem('Left', '₹${(totalBudget - totalSpent).toStringAsFixed(0)}', (totalBudget - totalSpent) < 0 ? AppConstants.dangerColor : AppConstants.successColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.sectionGap),
                  const SectionHeader('Categories · tap to set a budget'),
                  // Category wise
                  ..._categories.map((cat) {
                    final budget = _getBudgetForCategory(cat);
                    final spent = _getSpentForCategory(cat);
                    final budgetAmt = budget?.budgetAmount ?? 0;
                    final progress = budgetAmt > 0 ? (spent / budgetAmt).clamp(0.0, 1.5) : 0.0;
                    final isOverBudget = budgetAmt > 0 && spent > budgetAmt;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        borderColor: isOverBudget ? AppConstants.dangerColor.withOpacity(0.4) : null,
                        onTap: () => _showSetBudgetDialog(cat),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                Text(budgetAmt > 0 ? '₹${spent.toStringAsFixed(0)} / ₹${budgetAmt.toStringAsFixed(0)}' : spent > 0 ? '₹${spent.toStringAsFixed(0)} spent' : 'Set budget', style: TextStyle(fontSize: 12, color: isOverBudget ? AppConstants.dangerColor : context.mutedText)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Theme.of(context).dividerColor,
                                valueColor: AlwaysStoppedAnimation(isOverBudget ? AppConstants.dangerColor : progress > 0.8 ? AppConstants.warningColor : AppConstants.primaryColor),
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
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18))),
      ],
    );
  }
}
