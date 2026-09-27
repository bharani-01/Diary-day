class CustomAlert {
  final String id;
  final String? cowId;
  final String? cowTag;
  final String title;
  final DateTime alertDate;
  final String? alertTime;
  final bool isRecurring;
  final String? frequency;
  final bool isDismissed;
  final String? notes;
  final DateTime createdAt;

  CustomAlert({
    required this.id,
    this.cowId,
    this.cowTag,
    required this.title,
    required this.alertDate,
    this.alertTime,
    this.isRecurring = false,
    this.frequency,
    this.isDismissed = false,
    this.notes,
    required this.createdAt,
  });

  factory CustomAlert.fromJson(Map<String, dynamic> json) {
    return CustomAlert(
      id: json['id'],
      cowId: json['cow_id'],
      cowTag: json['cow_tag'],
      title: json['title'],
      alertDate: DateTime.parse(json['alert_date']),
      alertTime: json['alert_time'],
      isRecurring: json['is_recurring'] ?? false,
      frequency: json['frequency'],
      isDismissed: json['is_dismissed'] ?? false,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cow_id': cowId,
      'cow_tag': cowTag,
      'title': title,
      'alert_date': alertDate.toIso8601String().split('T')[0],
      'alert_time': alertTime,
      'is_recurring': isRecurring,
      'frequency': frequency,
      'is_dismissed': isDismissed,
      'notes': notes,
    };
  }
}
