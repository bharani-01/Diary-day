class CowMilkEstimate {
  final String id;
  final DateTime shiftEntryDate;
  final String shift;
  final String cowId;
  final double estimatedLiters;

  CowMilkEstimate({
    required this.id,
    required this.shiftEntryDate,
    required this.shift,
    required this.cowId,
    required this.estimatedLiters,
  });

  factory CowMilkEstimate.fromJson(Map<String, dynamic> json) {
    return CowMilkEstimate(
      id: json['id'],
      shiftEntryDate: DateTime.parse(json['shift_entry_date']),
      shift: json['shift'],
      cowId: json['cow_id'],
      estimatedLiters: (json['estimated_liters'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shift_entry_date': shiftEntryDate.toIso8601String().split('T')[0],
      'shift': shift,
      'cow_id': cowId,
      'estimated_liters': estimatedLiters,
    };
  }
}
