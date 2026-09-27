enum TodoPriority { low, medium, high }

class Todo {
  final String id;
  final String task;
  final String? description;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final TodoPriority priority;
  final String? cowId; // Link to a cow
  final String? cowTag; // For display
  final String? category; // Feed, Medical, etc.

  Todo({
    required this.id,
    required this.task,
    this.description,
    this.isDone = false,
    required this.createdAt,
    this.startTime,
    this.endTime,
    this.priority = TodoPriority.medium,
    this.cowId,
    this.cowTag,
    this.category,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      task: json['task'],
      description: json['description'],
      isDone: json['is_done'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      priority: _parsePriority(json['priority']),
      cowId: json['cow_id'],
      cowTag: json['cow_tag'],
      category: json['category'],
    );
  }

  static TodoPriority _parsePriority(String? p) {
    switch (p?.toLowerCase()) {
      case 'high': return TodoPriority.high;
      case 'low': return TodoPriority.low;
      default: return TodoPriority.medium;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'description': description,
      'is_done': isDone,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'priority': priority.name,
      'cow_id': cowId,
      'cow_tag': cowTag,
      'category': category,
    };
  }
}
