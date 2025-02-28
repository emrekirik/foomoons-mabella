import 'package:equatable/equatable.dart';

class Area extends Equatable {
  final int? id;
  final String? title;

  Area({this.id, required this.title});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] as int?,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }

  @override
  List<Object?> get props => [id, title];
}
