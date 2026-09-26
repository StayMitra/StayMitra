import 'building_model.dart';

class PgContext {
  static BuildingModel? activePg;

  static String? get activePgId => activePg?.id;

  static String get activePgName =>
      activePg?.name ?? 'No PG Selected';

  static String get activePgAddress =>
      activePg?.address ?? '';

  static void setActivePg(BuildingModel pg) {
    activePg = pg;
  }

  static void clear() {
    activePg = null;
  }
}