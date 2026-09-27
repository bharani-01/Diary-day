class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? notes;
  final bool isRecurring;
  final String? frequency; // 'daily', 'weekly', 'monthly'
  final String? cowId;
  final String? cowTag;
  final DateTime? lastAutoDate;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
    this.isRecurring = false,
    this.frequency,
    this.cowId,
    this.cowTag,
    this.lastAutoDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'] ?? 'Expense',
      category: json['category'] ?? 'Other',
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date']),
      notes: json['notes'],
      isRecurring: json['is_recurring'] ?? false,
      frequency: json['frequency'],
      cowId: json['cow_id'],
      cowTag: json['cow_tag'],
      lastAutoDate: json['last_auto_date'] != null ? DateTime.parse(json['last_auto_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'notes': notes,
      'is_recurring': isRecurring,
      'frequency': frequency,
      'cow_id': cowId,
      'cow_tag': cowTag,
      'last_auto_date': lastAutoDate?.toIso8601String().split('T')[0],
    };
  }
}
