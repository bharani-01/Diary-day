class BreedingRecord {
  final String id;
  final String cowId;
  final DateTime breedingDate;
  final String? details;
  final DateTime createdAt;

  BreedingRecord({
    required this.id,
    required this.cowId,
    required this.breedingDate,
    this.details,
    required this.createdAt,
  });

  // Gestation period for cows is typically 283 days
  DateTime get estimatedDeliveryDate => breedingDate.add(const Duration(days: 283));

  factory BreedingRecord.fromJson(Map<String, dynamic> json) {
    return BreedingRecord(
      id: json['id'],
      cowId: json['cow_id'],
      breedingDate: DateTime.parse(json['breeding_date']),
      details: json['details'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cow_id': cowId,
      'breeding_date': breedingDate.toIso8601String().split('T')[0],
      'details': details,
    };
  }
}
