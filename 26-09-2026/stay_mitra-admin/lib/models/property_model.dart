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
    return PropertyModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'PG',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] ?? '') ??
              DateTime.now(),
    );
  }
}