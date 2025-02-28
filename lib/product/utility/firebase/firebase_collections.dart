import 'package:cloud_firestore/cloud_firestore.dart';

enum FirebaseCollections {
  category,
  table,
  product,
  tableBill,
  order,
  token,
  pastOrders;

  CollectionReference get reference =>
      FirebaseFirestore.instance.collection(name);
}
