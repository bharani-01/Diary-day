class Payment {
  final String id;
  final String title;
  final double amount;
  final DateTime paymentDate;
  final String? description;
  final String? category; // e.g. 'Aavin', 'Private', 'Cow Sale'
  final DateTime? periodStart;
  final DateTime? periodEnd;

  Payment({
    required this.id,
    required this.title,
    required this.amount,
    required this.paymentDate,
    this.description,
    this.category,
    this.periodStart,
    this.periodEnd,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      title: json['title'] ?? 'Payment',
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      description: json['description'] ?? json['notes'], // mapping notes to description if needed
      category: json['category'],
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start']) : null,
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'description': description,
      'category': category,
      'period_start': periodStart?.toIso8601String().split('T')[0],
      'period_end': periodEnd?.toIso8601String().split('T')[0],
    };
  }
}
