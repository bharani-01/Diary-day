class ShiftMilkEntry {
  final String id;
  final double quantity;
  final String shift;
  final DateTime entryDate;
  final double? snf;
  final double? fatPercentage;

  ShiftMilkEntry({
    required this.id,
    required this.quantity,
    required this.shift,
    required this.entryDate,
    this.snf,
    this.fatPercentage,
  });

  factory ShiftMilkEntry.fromJson(Map<String, dynamic> json) {
    return ShiftMilkEntry(
      id: json['id'],
      quantity: (json['quantity'] as num).toDouble(),
      shift: json['shift'],
      entryDate: DateTime.parse(json['entry_date']),
      snf: json['snf'] != null ? (json['snf'] as num).toDouble() : null,
      fatPercentage: json['fat_percentage'] != null ? (json['fat_percentage'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'quantity': quantity,
      'shift': shift,
      'entry_date': entryDate.toIso8601String().split('T')[0],
    };
    if (snf != null) map['snf'] = snf!;
    if (fatPercentage != null) map['fat_percentage'] = fatPercentage!;
    return map;
  }
}
