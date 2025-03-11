import 'package:foomoons/product/utility/base/base_firebase_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class Menu with EquatableMixin, IdModel {
  final String? title;
  final double? price;
  final String? image;
  @override
  final int? id;
  final String? status;
  // final int? preparationTime;
  final String? category;
  final int? stock;
  final int? piece; // Yeni eklenen özellik
  final bool? isCredit;
  final bool? isAmount;
  final int? tableId; // Added tableId field
  final int? billId;  // Added billId field
  final String? orderType; // Added orderType field
  final String? customerMessage; // Added customerMessage field

  const Menu(
      {this.title,
      this.price,
      this.image,
      this.id,
      this.status = 'yeni',
      // this.preparationTime,
      this.category,
      this.stock,
      this.piece, // Constructor'a ekleyin
      this.isCredit,
      this.isAmount,
      this.tableId,
      this.billId,
      this.orderType,
      this.customerMessage}); // Added customerMessage to constructor

  @override
  List<Object?> get props => [
        title,
        price,
        image,
        status,
        // preparationTime,
        category,
        id,
        stock,
        piece,
        isCredit,
        isAmount,
        tableId,
        billId,
        orderType,
        customerMessage
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Menu) return false;

    return other.title == title &&
        other.price == price &&
        other.image == image &&
        other.status == status &&
        // other.preparationTime == preparationTime &&
        other.category == category &&
        other.id == id &&
        other.stock == stock &&
        other.piece == piece &&
        other.isCredit == isCredit &&
        other.tableId == tableId &&
        other.billId == billId &&
        other.orderType == orderType &&
        other.customerMessage == customerMessage;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        price.hashCode ^
        image.hashCode ^
        status.hashCode ^
        // preparationTime.hashCode ^
        category.hashCode ^
        id.hashCode ^
        stock.hashCode ^
        piece.hashCode ^
        isCredit.hashCode ^
        tableId.hashCode ^
        billId.hashCode ^
        orderType.hashCode ^
        customerMessage.hashCode;
  }

  /// Copy this instance with new values, while preserving existing ones if not provided
  Menu copyWith({
    String? title,
    double? price,
    String? image,
    String? status,
    int? preparationTime,
    String? category,
    int? id,
    int? stock,
    int? piece,
    bool? isCredit,
    bool? isAmount,
    int? tableId,
    int? billId,
    String? orderType,
    String? customerMessage,
  }) {
    return Menu(
        title: title ?? this.title,
        price: price ?? this.price,
        image: image ?? this.image,
        status: status ?? this.status,
        // preparationTime: preparationTime ?? this.preparationTime,
        category: category ?? this.category,
        id: id ?? this.id,
        stock: stock ?? this.stock,
        piece: piece ?? this.piece,
        isCredit: isCredit ?? this.isCredit,
        isAmount: isAmount ?? this.isAmount,
        tableId: tableId ?? this.tableId,
        billId: billId ?? this.billId,
        orderType: orderType ?? this.orderType,
        customerMessage: customerMessage ?? this.customerMessage);
  }

  /// Convert this Menu instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'image': image,
      'status': status,
      // 'preparationTime': preparationTime,
      'category': category,
      'stock': stock,
      'piece': piece,
      'isCredit': isCredit,
      'isAmount': isAmount,
      'tableId': tableId,
      'billId': billId,
      'orderType': orderType,
      'customerMessage': customerMessage
    };
  }

  /// Create a Menu instance from a JSON map
  static Menu fromJson(Map<String, dynamic> json) {
    return Menu(
        id: json['id'] as int?,
        title: json['title'] as String?,
        price: json['price'] as double?,
        image: json['image'] as String?,
        status: json['status'] as String?,
        // preparationTime: json['preparationTime'] != null
        //     ? (json['preparationTime'] as int)
        //     : null,
        category: json['category'] as String?,
        stock: _parseToInt(json['stock']),
        piece: _parseToInt(json['piece']),
        isCredit: json['isCredit'] as bool?,
        isAmount: json['isAmount'] as bool?,
        tableId: _parseToInt(json['tableId']),
        billId: _parseToInt(json['billId']),
        orderType: json['orderType'] as String?,
        customerMessage: json['customerMessage'] as String?);
  }

  /// Helper method to safely parse price values to int
  static int? _parseToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    } else {
      return null;
    }
  }

  @override
  String toString() {
    return 'Menu('
        'title: $title, '
        'price: $price, '
        'image: $image, '
        'status: $status, '
        'category: $category, '
        'id: $id, '
        'stock: $stock, '
        'piece: $piece, '
        'isCredit: $isCredit, '
        'isAmount: $isAmount, '
        'tableId: $tableId, '
        'billId: $billId, '
        'orderType: $orderType, '
        'customerMessage: $customerMessage)';
  }
}
