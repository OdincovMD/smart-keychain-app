import '../../domain/content/scene.dart';
import '../../domain/content/scene_repository.dart';

final class CompositeSceneRepository implements SceneRepository {
  CompositeSceneRepository(this._repositories);

  final List<SceneRepository> _repositories;

  @override
  Future<List<Scene>> getAll() async {
    final scenes = <Scene>[];
    for (final repository in _repositories) {
      scenes.addAll(await repository.getAll());
    }
    return List.unmodifiable(scenes);
  }

  @override
  Future<Scene?> getById(String id) async {
    for (final repository in _repositories) {
      final scene = await repository.getById(id);
      if (scene != null) return scene;
    }
    return null;
  }
}
