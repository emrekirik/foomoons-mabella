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
      this.billId}); // Added tableId and billId to constructor

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
        piece, // Listeye ekleyin
        isCredit,
        isAmount,
        tableId, // Added to props
        billId // Added to props
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
        other.piece == piece && // Eşitlik kontrolüne ekleyin
        other.isCredit == isCredit &&
        other.tableId == tableId &&
        other.billId == billId; // Added to equality check
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
        billId.hashCode; // Added to hashCode
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
    int? piece, // copyWith methoduna ekleyin
    bool? isCredit,
    bool? isAmount,
    int? tableId, // Added to copyWith
    int? billId,  // Added to copyWith
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
        piece: piece ?? this.piece, // Değer atama yapın
        isCredit: isCredit ?? this.isCredit,
        isAmount: isAmount ?? this.isAmount,
        tableId: tableId ?? this.tableId,
        billId: billId ?? this.billId); // Added to copyWith return
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
      'piece': piece, // JSON dönüşümüne ekleyin
      'isCredit': isCredit,
      'isAmount': isAmount,
      'tableId': tableId, // Added to toJson
      'billId': billId // Added to toJson
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
        piece: _parseToInt(json['piece']), // JSON'dan `piece` değerini alın
        isCredit: json['isCredit'] as bool?,
        isAmount: json['isAmount'] as bool?,
        tableId: _parseToInt(json['tableId']),
        billId: _parseToInt(json['billId'])); // Added to fromJson
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
        'billId: $billId)';
  }
}
