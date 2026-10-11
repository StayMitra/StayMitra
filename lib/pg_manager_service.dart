import 'package:cloud_firestore/cloud_firestore.dart';

import 'building_model.dart';
import 'pg_context.dart';
import 'services/user_access_service.dart';

class PgManagerService {
  static Future<List<BuildingModel>> getAllPgs({
    required String ownerId,
  }) async {
    final access = UserAccessService.instance;
    final actualOwnerId = await access.ownerId();

    if (actualOwnerId == null || actualOwnerId.trim().isEmpty) {
      throw Exception('PG owner ID is missing.');
    }

    final properties = await access.getAllowedProperties();

    final pgs = properties.map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final rawAddress = (data['address'] ?? '').toString();
      final rawCreatedAt = data['createdAt'] ?? data['created_at'];

      DateTime createdAt;
      if (rawCreatedAt is Timestamp) {
        createdAt = rawCreatedAt.toDate();
      } else if (rawCreatedAt is DateTime) {
        createdAt = rawCreatedAt;
      } else {
        createdAt = DateTime.tryParse(rawCreatedAt?.toString() ?? '') ??
            DateTime.now();
      }

      return BuildingModel(
        id: doc.id,
        name: (data['name'] ?? '').toString(),
        address: rawAddress.trim().isEmpty ? null : rawAddress,
        createdAt: createdAt,
        ownerId: actualOwnerId,
      );
    }).toList();

    pgs.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return pgs;
  }

  static Future<void> selectPg(
    BuildingModel pg, {
    required String ownerId,
  }) async {
    final access = UserAccessService.instance;
    final allowed = await access.canAccessProperty(pg.id);

    if (!allowed) {
      throw Exception('You are not authorized to access this PG.');
    }

    final actualOwnerId = await access.ownerId();

    if (actualOwnerId == null || actualOwnerId != pg.ownerId) {
      throw Exception('PG owner does not match the logged-in account.');
    }

    PgContext.setActivePg(pg);
  }

  static BuildingModel? get activePg => PgContext.activePg;

  static String? get activePgId => PgContext.activePg?.id;
}
