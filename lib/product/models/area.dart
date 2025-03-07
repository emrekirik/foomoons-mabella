class Area {
  final int id;
  final String title;
  final int businessId;

  Area({
    required this.id,
    required this.title,
    required this.businessId,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] as int,
      title: json['title'] as String,
      businessId: json['businessId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'businessId': businessId,
    };
  }
} 