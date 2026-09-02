import 'scene.dart';

abstract interface class SceneRepository {
  Future<List<Scene>> getAll();

  Future<Scene?> getById(String id);
}
