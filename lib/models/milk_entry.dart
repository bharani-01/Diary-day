class MilkEntry {
  final String id;
  final String cowId;
  final double quantity;
  final String shift;
  final DateTime entryDate;
  final String? cowTag; // Joined data

  MilkEntry({
    required this.id,
    required this.cowId,
    required this.quantity,
    required this.shift,
    required this.entryDate,
    this.cowTag,
  });

  factory MilkEntry.fromJson(Map<String, dynamic> json) {
    return MilkEntry(
      id: json['id'],
      cowId: json['cow_id'],
      quantity: (json['quantity'] as num).toDouble(),
      shift: json['shift'],
      entryDate: DateTime.parse(json['entry_date']),
      cowTag: json['cows'] != null ? json['cows']['tag_number'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cow_id': cowId,
      'quantity': quantity,
      'shift': shift,
      'entry_date': entryDate.toIso8601String().split('T')[0],
    };
  }
}
