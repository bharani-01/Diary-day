class MilkGoal {
  final String id;
  final double targetLiters;
  final int month;
  final int year;

  MilkGoal({
    required this.id,
    required this.targetLiters,
    required this.month,
    required this.year,
  });

  factory MilkGoal.fromJson(Map<String, dynamic> json) {
    return MilkGoal(
      id: json['id'],
      targetLiters: (json['target_liters'] as num).toDouble(),
      month: json['month'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_liters': targetLiters,
      'month': month,
      'year': year,
    };
  }
}
