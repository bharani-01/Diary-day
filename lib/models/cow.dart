class Cow {
  final String id;
  final String tagNumber;
  final String? name;
  final String? breed;
  final int? age;
  final String healthStatus;
  final String? imageUrl;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final String cowType;
  final bool? isBornInFarm;
  final String? motherCowId;
  final String status; // Active, Sold, Deceased
  final bool isDry;
  final String? buyerName;
  final double? salePrice;
  final DateTime? saleDate;
  final String? source;
  final double? purchasePrice;
  final String? healthAtPurchase;
  final DateTime? dob;

  Cow({
    required this.id,
    required this.tagNumber,
    this.name,
    this.breed,
    this.age,
    required this.healthStatus,
    this.imageUrl,
    this.imageUrls,
    required this.createdAt,
    this.cowType = 'Cow',
    this.isBornInFarm,
    this.motherCowId,
    this.status = 'Active',
    this.isDry = false,
    this.buyerName,
    this.salePrice,
    this.saleDate,
    this.source,
    this.purchasePrice,
    this.healthAtPurchase,
    this.dob,
  });

  factory Cow.fromJson(Map<String, dynamic> json) {
    return Cow(
      id: json['id'],
      tagNumber: json['tag_number'],
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      healthStatus: json['health_status'] ?? 'Healthy',
      imageUrl: json['image_url'],
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : null,
      createdAt: DateTime.parse(json['created_at']),
      cowType: json['cow_type'] ?? 'Cow',
      isBornInFarm: json['is_born_in_farm'],
      motherCowId: json['mother_cow_id'],
      status: json['status'] ?? 'Active',
      isDry: json['is_dry'] ?? false,
      buyerName: json['buyer_name'],
      salePrice: json['sale_price'] != null ? (json['sale_price'] as num).toDouble() : null,
      saleDate: json['sale_date'] != null ? DateTime.parse(json['sale_date']) : null,
      source: json['source'],
      purchasePrice: json['purchase_price'] != null ? (json['purchase_price'] as num).toDouble() : null,
      healthAtPurchase: json['health_at_purchase'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
    );
  }

  String get formattedAge {
    if (age == null && dob == null) return 'Unknown Age';
    
    final now = DateTime.now();
    final referenceDate = dob ?? createdAt;
    
    int monthsDiff = (now.year - referenceDate.year) * 12 + now.month - referenceDate.month;
    if (now.day < referenceDate.day) {
      monthsDiff--;
    }
    if (monthsDiff < 0) monthsDiff = 0;
    
    final totalMonths = (age != null ? (age! * 12) : 0) + monthsDiff;
    final displayYears = totalMonths ~/ 12;
    final displayMonths = totalMonths % 12;
    
    if (displayYears == 0) return '$displayMonths Mos';
    if (displayMonths == 0) return '$displayYears Yrs';
    return '$displayYears Yrs, $displayMonths Mos';
  }

  String get dynamicCowType {
    // If it's a bull or buffalo, just return the static type
    if (cowType.toLowerCase() == 'bull' || cowType.toLowerCase() == 'buffalo') return cowType;

    int totalMonths = 0;
    final referenceDate = dob ?? createdAt;
    if (age != null || dob != null) {
      final now = DateTime.now();
      int monthsDiff = (now.year - referenceDate.year) * 12 + now.month - referenceDate.month;
      if (now.day < referenceDate.day) {
        monthsDiff--;
      }
      if (monthsDiff < 0) monthsDiff = 0;
      totalMonths = (age != null ? (age! * 12) : 0) + monthsDiff;
    }

    if (totalMonths < 6) {
      return 'Calf';
    } else if (totalMonths < 24) {
      return 'Heifer';
    } else {
      return 'Cow';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tag_number': tagNumber,
      'name': name,
      'breed': breed,
      'age': age,
      'health_status': healthStatus,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'cow_type': cowType,
      'is_born_in_farm': isBornInFarm,
      'mother_cow_id': motherCowId,
      'status': status,
      'is_dry': isDry,
      'buyer_name': buyerName,
      'sale_price': salePrice,
      'sale_date': saleDate?.toIso8601String().split('T')[0],
      'source': source,
      'purchase_price': purchasePrice,
      'health_at_purchase': healthAtPurchase,
      'dob': dob?.toIso8601String().split('T')[0],
    };
  }
}
