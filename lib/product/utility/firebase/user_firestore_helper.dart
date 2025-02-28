import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFirestoreHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  String? _currentCafeId; // Cache için bir değişken

  /// Kullanıcıya özel bir koleksiyon referansı al
  CollectionReference getUserCollection(String collectionName) {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection(collectionName);
  }

/*   Future<Map<String, dynamic>?> getCurrentUserDetails() async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    // Kullanıcının Firestore belgesini al
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    return userDoc.data();
  } */

  /// Kullanıcıya özel koleksiyon içindeki belirli bir belge referansını al
  DocumentReference getUserDocument(String collectionName, String documentId) {
    return getUserCollection(collectionName).doc(documentId);
  }

  /// Kullanıcı türünü (örneğin 'çalışan' veya 'kafe') almak için bir yardımcı işlev
  Future<String?> getUserType() async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final userData = userDoc.data();
    return userData?['userType'] as String?;
  }

  /// Kullanıcının bağlı olduğu cafeId değerini almak için bir yardımcı işlev
  Future<String?> getCafeId() async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final userData = userDoc.data();
    return userData?['cafeId'] as String?;
  }

  /// Cache edilmiş cafeId'yi almak için bir getter
  Future<String?> get currentCafeId async {
    if (_currentCafeId != null) {
      return _currentCafeId; // Eğer cache varsa direkt dön
    }
    _currentCafeId = await getCafeId(); // Asenkron olarak cafeId al ve cache et
    return _currentCafeId;
  }

  /// Belirli bir koleksiyondaki belgeleri bir sorgu ile al
  Query getCollectionWithQuery(
      String collectionName, String field, dynamic value) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .where(field, isEqualTo: value);
  }

  /// Kullanıcıya özel bir belgenin varlığını kontrol et
  Future<bool> checkDocumentExists(
      String collectionName, String documentId) async {
    final docRef = getUserDocument(collectionName, documentId);
    final docSnapshot = await docRef.get();
    return docSnapshot.exists;
  }
}
