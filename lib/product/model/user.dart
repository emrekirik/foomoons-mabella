import 'package:foomoons/product/utility/base/base_firebase_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class User with EquatableMixin, IdModel {
  final String? name;
  final String? image;
  final String? appellation;
  @override
  final int? id;

  const User({
    this.name,
    this.image,
    this.id,
    this.appellation,
  });

  @override
  List<Object?> get props => [name, image, id, appellation];

  User copyWith({
    int? id,
    String? name,
    String? image,
    String? appellation,
  }) {
    return User(
      name: name ?? this.name,
      image: image ?? this.image,
      id: id ?? this.id,
      appellation: appellation ?? this.appellation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'appellation': appellation,
      'id': id,
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String?,
      image: json['image'] as String?,
      appellation: json['appellation'] as String?,
      id: json['id'] as int?,
    );
  }
}
