import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusPill(label: 'Expense', color: AppConstants.dangerColor, icon: Icons.north_east),
                      const SizedBox(height: 12),
                      Text(
                        '₹ ${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _detailRow(context, Icons.label_outline, 'Item', expense.title),
                      const Divider(height: 1),
                      _detailRow(context, Icons.category_outlined, 'Category', expense.category),
                      const Divider(height: 1),
                      _detailRow(context, Icons.calendar_today_outlined, 'Expense date', DateFormat('EEEE, MMM d, y').format(expense.expenseDate)),
                      
                      if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                        const Divider(height: 1),
                        _detailRow(context, Icons.notes, 'Notes', expense.notes!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.mutedText),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: context.mutedText)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
