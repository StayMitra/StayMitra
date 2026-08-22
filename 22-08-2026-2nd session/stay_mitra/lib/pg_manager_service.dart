import 'building_model.dart';
import 'database_helper.dart';
import 'pg_context.dart';

class PgManagerService {
  // ------------------------------------------------------------
  // GET ALL PGs FOR OWNER
  // ------------------------------------------------------------

  static Future<List<BuildingModel>> getAllPgs({
    required String ownerId,
  }) async {
    return DatabaseHelper.instance.getBuildings(
      ownerId: ownerId,
    );
  }

  // ------------------------------------------------------------
  // SELECT / SWITCH ACTIVE PG
  // ------------------------------------------------------------

  static Future<void> selectPg(
    BuildingModel pg, {
    required String ownerId,
  }) async {
    // Make sure the PG belongs to the current owner.
    if (pg.ownerId != ownerId) {
      throw Exception(
        'You are not authorized to access this PG.',
      );
    }

    // Save ONLY this PG as active PG.
    PgContext.setActivePg(pg);
  }

  // ------------------------------------------------------------
  // CURRENT ACTIVE PG
  // ------------------------------------------------------------

  static BuildingModel? get activePg {
    return PgContext.activePg;
  }

  // ------------------------------------------------------------
  // CURRENT ACTIVE PG ID
  // ------------------------------------------------------------

  static String? get activePgId {
    return PgContext.activePg?.id;
  }
}