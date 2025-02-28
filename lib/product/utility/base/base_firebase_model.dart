import 'package:foomoons/product/utility/exception/custom_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

mixin IdModel {
  int? get id;
}

mixin BaseFirebaseModel<T extends IdModel> {
  T fromJson(Map<String, dynamic> json);

  T fromFirebase(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final Map<String, dynamic>? value = snapshot.data();
    if (value == null) {
      throw FirebaseCustomException('$snapshot data is null');
    }
    value['id'] = snapshot.id; // id'yi data'ya ekleme
    return fromJson(value);
  }
}
