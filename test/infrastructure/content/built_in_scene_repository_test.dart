import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';

void main() {
  group('BuiltInSceneRepository', () {
    late BuiltInSceneRepository repository;

    setUp(() => repository = BuiltInSceneRepository());

    test('getAll returns every built-in scene', () async {
      final scenes = await repository.getAll();

      expect(scenes, hasLength(3));
      expect(
        scenes.map((scene) => scene.id),
        containsAll({
          BuiltInSceneRepository.livingEyesId,
          BuiltInSceneRepository.mintEyesId,
          BuiltInSceneRepository.sunnyFriendId,
        }),
      );
      expect(
        scenes.every((scene) => scene.source == SceneSource.builtIn),
        isTrue,
      );
    });

    test('getById returns the requested scene', () async {
      final scene = await repository.getById(
        BuiltInSceneRepository.livingEyesId,
      );

      expect(scene?.name, 'Живой взгляд');
      expect(scene?.id, BuiltInSceneRepository.livingEyesId);
    });

    test('getById returns null for an unknown id', () async {
      expect(await repository.getById('missing-scene'), isNull);
    });

    test('resolves procedural and static scene content', () async {
      final livingEyes = await repository.getById(
        BuiltInSceneRepository.livingEyesId,
      );
      final mintEyes = await repository.getById(
        BuiltInSceneRepository.mintEyesId,
      );

      expect(livingEyes?.type, SceneType.proceduralEyes);
      expect(livingEyes?.content, isA<ProceduralEyesContent>());
      expect(livingEyes?.animated, isTrue);
      expect(mintEyes?.type, SceneType.staticImage);
      expect(mintEyes?.content, isA<StaticImageContent>());
      expect(mintEyes?.animated, isFalse);
    });
  });
}
