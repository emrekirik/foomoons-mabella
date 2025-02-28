import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/utility/base/base_firebase_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class CoffeTable with EquatableMixin, IdModel {
  final String? area;
  final String? tableTitle;
  final String? qrUrl;
  final List<Menu>? billItems;
  @override
  final int? id;

  CoffeTable({this.tableTitle, this.billItems, this.id, this.qrUrl, this.area});

  @override
  List<Object?> get props => [tableTitle, billItems, id, qrUrl, area];

  CoffeTable copyWith(
      {int? id,
      String? tableTitle,
      List<Menu>? billItems,
      String? qrUrl,
      String? area}) {
    return CoffeTable(
        tableTitle: tableTitle ?? this.tableTitle,
        billItems: billItems ?? this.billItems,
        id: id,
        qrUrl: qrUrl ?? this.qrUrl,
        area: area ?? this.area);
  }

  Map<String, dynamic> toJson() {
    return {
      'tableTitle': tableTitle,
      'billItems': billItems?.map((item) => item.toJson()).toList(),
      'id': id,
      'qrUrl': qrUrl,
      'area': area
    };
  }

  static CoffeTable fromJson(Map<String, dynamic> json) {
    return CoffeTable(
        tableTitle: json['tableTitle'] as String?,
        billItems: (json['billItems'] as List<dynamic>?)
            ?.map((item) => Menu.fromJson(item as Map<String, dynamic>))
            .toList(),
        id: json['id'] as int?,
        qrUrl: json['qrUrl'] as String?,
        area: json['area'] as String?);
  }
}
