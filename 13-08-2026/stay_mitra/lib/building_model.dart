class BuildingModel {
  final String id;
  final String name;
  final String? address;
  final DateTime createdAt;

  const BuildingModel({
    required this.id,
    required this.name,
    this.address,
    required this.createdAt,
  });
}

class FloorModel {
  final String id;
  final String buildingId;
  final String name;
  final int floorOrder;
  final DateTime createdAt;

  const FloorModel({
    required this.id,
    required this.buildingId,
    required this.name,
    required this.floorOrder,
    required this.createdAt,
  });
}

class RoomModel {
  final String id;
  final String floorId;
  final String roomNumber;
  final int bedCount;
  final DateTime createdAt;

  const RoomModel({
    required this.id,
    required this.floorId,
    required this.roomNumber,
    required this.bedCount,
    required this.createdAt,
  });
}

class BedModel {
  final String id;
  final String roomId;
  final String bedNumber;
  final String status;
  final DateTime createdAt;

  const BedModel({
    required this.id,
    required this.roomId,
    required this.bedNumber,
    this.status = 'available',
    required this.createdAt,
  });

  bool get isAvailable => status == 'available';

  bool get isOccupied => status == 'occupied';
}