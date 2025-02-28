import 'package:foomoons/product/utility/base/base_firebase_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class Category with EquatableMixin, IdModel {
  final String? title;
  @override
  final int? id;

  Category({this.title, this.id});

  @override
  List<Object?> get props => [title, id];

  Category copyWith({
    String? title,
    int? id, // Added the id to the copyWith method
  }) {
    return Category(
      title: title ?? this.title,
      id: id ?? this.id, // Ensure the id is copied as well
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }

  static Category fromJson(Map<String, dynamic> json) {
    return Category(
      title: json['title'] as String?,
      id: json['id'] as int?, // Ensure the id is parsed from JSON
    );
  }
}
