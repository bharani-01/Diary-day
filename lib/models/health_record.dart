class HealthRecord {
  final String id;
  final String cowId;
  final String treatment; // e.g., "FMD Vaccination", "Deworming"
  final DateTime date;
  final String? administeredBy; // e.g., "Dr. Sharma", "Self"
  final String? notes;
  final String type; // e.g., "Vaccination", "Injury", "Routine"

  HealthRecord({
    required this.id,
    required this.cowId,
    required this.treatment,
    required this.date,
    this.administeredBy,
    this.notes,
    required this.type,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'],
      cowId: json['cow_id'],
      treatment: json['treatment'],
      date: DateTime.parse(json['date']),
      administeredBy: json['administered_by'],
      notes: json['notes'],
      type: json['type'] ?? 'Treatment',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cow_id': cowId,
      'treatment': treatment,
      'date': date.toIso8601String().split('T')[0],
      'administered_by': administeredBy,
      'notes': notes,
      'type': type,
    };
  }
}
