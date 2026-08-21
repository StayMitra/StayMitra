import 'building_model.dart';
import 'database_helper.dart';
import 'pg_context.dart';

class PgManagerService {
  // ------------------------------------------------------------
  // CURRENT OWNER
  // ------------------------------------------------------------
  //
  // Temporary owner ID.
  // Later, when login/authentication is added,
  // this should come from the logged-in user's ID.
  //
  static const String ownerId = 'default_owner';

  // ------------------------------------------------------------
  // GET ALL PGs FOR CURRENT OWNER
  // ------------------------------------------------------------

  static Future<List<BuildingModel>> getAllPgs() async {
    return DatabaseHelper.instance.getBuildings(
      ownerId: ownerId,
    );
  }

  // ------------------------------------------------------------
  // SELECT / SWITCH ACTIVE PG
  // ------------------------------------------------------------

  static Future<void> selectPg(BuildingModel pg) async {
    // Make sure the PG belongs to the current owner.
    if (pg.ownerId != ownerId) {
      throw Exception(
        'You are not authorized to access this PG.',
      );
    }

    // Save selected PG as active PG.
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