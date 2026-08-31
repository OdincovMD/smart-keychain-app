import '../../domain/content/scene.dart';

abstract final class BuiltInSceneCatalog {
  static const mintEyesId = 'eyes_mint_static_v1';
  static const sunnyFriendId = 'sunny_friend_static_v1';

  static const scenes = <Scene>[
    Scene(
      id: mintEyesId,
      titleKey: 'sceneMintEyes',
      descriptionKey: 'sceneMintEyesDescription',
      previewAssetId: mintEyesId,
      type: SceneType.staticImage,
      source: SceneSource.builtIn,
    ),
    Scene(
      id: sunnyFriendId,
      titleKey: 'sceneSunnyFriend',
      descriptionKey: 'sceneSunnyFriendDescription',
      previewAssetId: sunnyFriendId,
      type: SceneType.staticImage,
      source: SceneSource.builtIn,
    ),
  ];

  static Scene? byId(String id) {
    for (final scene in scenes) {
      if (scene.id == id) return scene;
    }
    return null;
  }
}

abstract final class SceneAssetResolver {
  static String resolve(String previewAssetId) =>
      'assets/scenes/$previewAssetId.png';
}
