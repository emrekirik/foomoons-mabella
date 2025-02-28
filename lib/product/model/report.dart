import 'package:foomoons/product/utility/base/base_firebase_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class Report with EquatableMixin, IdModel {
  final int? totalProduct;
  final int? totalRevenues;
  final int? totalOrder;
  @override
  final int? id;

  const Report({
    this.totalProduct,
    this.totalRevenues,
    this.id,
    this.totalOrder,
  });

  @override
  List<Object?> get props => [totalProduct, totalRevenues, id, totalOrder];

  Report copyWith({
    int? id,
    int? totalProduct,
    int? totalRevenues,
    int? totalOrder,
  }) {
    return Report(
      totalProduct: totalProduct ?? this.totalProduct,
      totalRevenues: totalRevenues ?? this.totalRevenues,
      id: id ?? this.id,
      totalOrder: totalOrder ?? this.totalOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProduct': totalProduct,
      'totalRevenues': totalRevenues,
      'totalOrder': totalOrder,
      'id': id,
    };
  }

  static Report fromJson(Map<String, dynamic> json) {
    return Report(
      totalProduct: json['totalProduct'] as int?,
      totalRevenues: json['totalRevenues'] as int?,
      totalOrder: json['totalOrder'] as int?,
      id: json['id'] as int?,
    );
  }
}
