class MonthlyBudget {
  final String id;
  final String category;
  final double budgetAmount;
  final int month;
  final int year;

  MonthlyBudget({
    required this.id,
    required this.category,
    required this.budgetAmount,
    required this.month,
    required this.year,
  });

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    return MonthlyBudget(
      id: json['id'],
      category: json['category'],
      budgetAmount: (json['budget_amount'] as num).toDouble(),
      month: json['month'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'budget_amount': budgetAmount,
      'month': month,
      'year': year,
    };
  }
}
