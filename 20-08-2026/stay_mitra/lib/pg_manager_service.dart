import 'building_model.dart';
import 'database_helper.dart';
import 'pg_context.dart';

class PgManagerService {
  static Future<List<BuildingModel>> getAllPgs() async {
    return DatabaseHelper.instance.getBuildings();
  }

  static Future<void> selectPg(BuildingModel pg) async {
    PgContext.setActivePg(pg);
  }

  static BuildingModel? get activePg {
    return PgContext.activePg;
  }
}