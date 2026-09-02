import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_repository.dart';

void main() {
  test('device scene selection resolves through SceneRepository', () async {
    final scenes = BuiltInSceneRepository();
    final device = VirtualDeviceRepository(
      engine: VirtualDeviceEngine(
        sceneRepository: scenes,
        initialSceneId: BuiltInSceneRepository.livingEyesId,
        latency: Duration.zero,
      ),
    );
    addTearDown(device.dispose);
    await device.connect(VirtualDeviceEngine.deviceId);
    final committed = device.watchDeviceState().firstWhere(
      (snapshot) => snapshot.activeSceneId == BuiltInSceneRepository.mintEyesId,
    );

    await device.setScene(BuiltInSceneRepository.mintEyesId);
    final snapshot = await committed;
    final activeScene = await scenes.getById(snapshot.activeSceneId);

    expect(activeScene?.id, BuiltInSceneRepository.mintEyesId);
    expect(activeScene?.type, SceneType.staticImage);
    expect(activeScene?.content, isA<StaticImageContent>());
  });
}
