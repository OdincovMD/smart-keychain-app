import '../../domain/content/scene.dart';
import '../../domain/content/scene_repository.dart';
import '../../domain/eyes/eye_emotion.dart';

final class BuiltInSceneRepository implements SceneRepository {
  static const livingEyesId = 'living_eyes_v1';
  static const mintEyesId = 'eyes_mint_static_v1';
  static const sunnyFriendId = 'sunny_friend_static_v1';

  static const _scenes = <Scene>[
    Scene(
      id: livingEyesId,
      name: 'Живой взгляд',
      description: 'Сам моргает, наблюдает и меняет настроение.',
      content: ProceduralEyesContent(defaultEmotion: EyeEmotion.neutral),
      source: SceneSource.builtIn,
      tags: {'eyes', 'animated'},
    ),
    Scene(
      id: mintEyesId,
      name: 'Мятный взгляд',
      description: 'Спокойные глаза с тёплой искрой.',
      content: StaticImageContent(
        previewAssetPath: 'assets/scenes/eyes_mint_static_v1.png',
      ),
      source: SceneSource.builtIn,
      tags: {'eyes', 'static'},
    ),
    Scene(
      id: sunnyFriendId,
      name: 'Солнечный друг',
      description: 'Коралловое настроение на весь день.',
      content: StaticImageContent(
        previewAssetPath: 'assets/scenes/sunny_friend_static_v1.png',
      ),
      source: SceneSource.builtIn,
      tags: {'face', 'static'},
    ),
  ];

  @override
  Future<List<Scene>> getAll() async => List.unmodifiable(_scenes);

  @override
  Future<Scene?> getById(String id) async {
    for (final scene in _scenes) {
      if (scene.id == id) return scene;
    }
    return null;
  }
}
