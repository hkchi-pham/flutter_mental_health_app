import '../../shared/models/garden_model.dart';

abstract class GardenRepository {
  Future<GardenState> getGardenState();
  Future<void> saveGardenState(GardenState state);
}
