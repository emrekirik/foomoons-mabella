import 'package:foomoons/product/model/menu.dart';
import 'package:foomoons/product/utility/base/base_firebase_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class Order with EquatableMixin, IdModel {
  final String? title;
  final double? price;
  final String? image;
  final int? piece;
  final int? preperationTime;
  final String? tableTitle;
  final String? status;
  final int? productId;
  final int? businessId;
  final Timestamp? orderDate; // Yeni alan eklendi
  final String? customerMessage;
  final String? orderType;
  @override
  final int? id;

  const Order({
    this.title,
    this.price,
    this.image,
    this.id,
    this.piece,
    this.preperationTime,
    this.tableTitle,
    this.status = 'yeni',
    this.productId,
    this.orderDate, // Constructor'a eklendi
    this.businessId,
    this.customerMessage,
    this.orderType,
  });

  @override
  List<Object?> get props => [
        title,
        price,
        image,
        id,
        preperationTime,
        piece,
        tableTitle,
        status,
        productId,
        orderDate, // Eşitlik kontrolüne eklendi
        businessId,
        customerMessage,
        orderType,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Order) return false;

    return other.title == title &&
        other.price == price &&
        other.image == image &&
        other.id == id &&
        other.piece == piece &&
        other.preperationTime == preperationTime &&
        other.tableTitle == tableTitle &&
        other.status == status &&
        other.productId == productId &&
        other.orderDate == orderDate &&
        other.businessId == businessId &&
        other.customerMessage == customerMessage &&
        other.orderType == orderType;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        price.hashCode ^
        image.hashCode ^
        id.hashCode ^
        piece.hashCode ^
        preperationTime.hashCode ^
        tableTitle.hashCode ^
        status.hashCode ^
        productId.hashCode ^
        orderDate.hashCode ^
        businessId.hashCode ^
        customerMessage.hashCode ^
        orderType.hashCode;
  }

  Order copyWith({
    String? title,
    int? id,
    double? price,
    String? image,
    int? piece,
    int? preperationTime,
    String? tableTitle,
    String? status,
    Menu? menu,
    int? productId,
    Timestamp? orderDate, // copyWith metoduna eklendi
    int? businessId,
    String? customerMessage,
    String? orderType,
  }) {
    return Order(
      title: title ?? this.title,
      price: price ?? this.price,
      image: image ?? this.image,
      piece: piece ?? this.piece,
      preperationTime: preperationTime ?? this.preperationTime,
      tableTitle: tableTitle ?? this.tableTitle,
      status: status ?? this.status,
      id: id ?? this.id,
      productId: productId ?? this.productId,
      orderDate: orderDate ?? this.orderDate, // Yeni alan için güncellendi
      businessId: businessId ?? this.businessId,
      customerMessage: customerMessage ?? this.customerMessage,
      orderType: orderType ?? this.orderType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'image': image,
      'piece': piece,
      'preperationTime': preperationTime,
      'tableTitle': tableTitle,
      'status': status,
      'productId': productId,
      'orderDate': orderDate, // JSON'a eklendi
      'businessId': businessId,
      'customerMessage': customerMessage,
      'orderType': orderType,
    };
  }


  static Order fromJson(Map<String, dynamic> json) {
    Timestamp? parseOrderDate(dynamic value) {
      if (value == null) return null;
      try {
        if (value is Timestamp) return value;
        if (value is String) {
          final date = DateTime.parse(value);
          // Ensure the date is not before 1970 to avoid invalid timestamps
          if (date.isBefore(DateTime(1970))) {
            return Timestamp.now();
          }
          return Timestamp.fromDate(date);
        }
        return null;
      } catch (e) {
        print('Error parsing orderDate: $e');
        return null;
      }
    }

    return Order(
      id: json['id'] as int?,
      title: json['title'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      image: json['image'] as String?,
      piece: json['piece'] != null ? (json['piece'] as num).toInt() : null,
      preperationTime: json['preprationTime'] != null
          ? (json['preprationTime'] is String 
              ? DateTime.parse(json['preprationTime'] as String).millisecondsSinceEpoch ~/ 1000
              : (json['preprationTime'] as num).toInt())
          : null,
      tableTitle: json['tableTitle'] as String?,
      status: json['status'] as String?,
      productId: json['productId'] != null ? (json['productId'] as num).toInt() : null,
      orderDate: parseOrderDate(json['orderDate']),
      businessId: json['businessId'] != null ? (json['businessId'] as num).toInt() : null,
      customerMessage: json['customerMessage'] as String?,
      orderType: json['orderType'] as String?,
    );
  }
}

