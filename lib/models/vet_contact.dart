class VetContact {
  final String id;
  final String name;
  final String phone;
  final String? specialty;
  final String? notes;
  final DateTime createdAt;

  VetContact({
    required this.id,
    required this.name,
    required this.phone,
    this.specialty,
    this.notes,
    required this.createdAt,
  });

  factory VetContact.fromJson(Map<String, dynamic> json) {
    return VetContact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      specialty: json['specialty'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'specialty': specialty,
      'notes': notes,
    };
  }
}
