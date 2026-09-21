import 'package:firebase_auth/firebase_auth.dart';

import '../models/property_model.dart';
import 'firestore_service.dart';

class PropertyService {
  PropertyService._();

  static final PropertyService instance =
      PropertyService._();

  final FirestoreService _firestore =
      FirestoreService.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String get _ownerId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  Future<void> createProperty(
    PropertyModel property,
  ) async {
    final ownerId = _ownerId;

    if (property.ownerId != ownerId) {
      throw Exception(
        'Property owner does not match logged-in user.',
      );
    }

    await _firestore
        .propertyDocument(
          ownerId,
          property.id,
        )
        .set(property.toMap());
  }

  Future<List<PropertyModel>> getProperties() async {
    final ownerId = _ownerId;

    final snapshot = await _firestore
        .propertiesCollection(ownerId)
        .get();

    return snapshot.docs
        .map(
          (doc) => PropertyModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }
}