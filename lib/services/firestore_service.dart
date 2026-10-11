import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance =
      FirestoreService._();

  final FirebaseFirestore db =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      ownerCollection() {
    return db.collection('owners');
  }

  DocumentReference<Map<String, dynamic>>
      ownerDocument(String ownerId) {
    return ownerCollection().doc(ownerId);
  }

  CollectionReference<Map<String, dynamic>>
      propertiesCollection(String ownerId) {
    return ownerDocument(ownerId)
        .collection('properties');
  }

  DocumentReference<Map<String, dynamic>>
      propertyDocument(
    String ownerId,
    String propertyId,
  ) {
    return propertiesCollection(ownerId)
        .doc(propertyId);
  }
}