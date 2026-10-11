import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String address;
  final String city;
  final String state;
  final DateTime createdAt;

  const PropertyModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.state,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'type': type,
      'address': address,
      'city': city,
      'state': state,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PropertyModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final rawCreatedAt = map['createdAt'];

    DateTime parsedCreatedAt;

    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedCreatedAt =
          DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return PropertyModel(
      id: id,
      ownerId: (map['ownerId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? 'PG').toString(),
      address: (map['address'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      state: (map['state'] ?? '').toString(),
      createdAt: parsedCreatedAt,
    );
  }
}