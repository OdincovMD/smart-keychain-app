import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_keychain_app/domain/image/crop_spec.dart';
import 'package:smart_keychain_app/features/image_editor/image_editor_controller.dart';

void main() {
  test('pan, zoom, rotate, and reset stay normalized', () {
    final container = ProviderContainer.test();
    const initial = CropSpec.centered;
    final provider = imageEditorControllerProvider(
      const ImageEditorSession(assetId: 'asset-1', initialCropSpec: initial),
    );
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);

    controller.applyGesture(
      start: CropSpec.centered,
      deltaX: 0.2,
      deltaY: -0.3,
      scaleFactor: 2,
    );
    var crop = container.read(provider);
    expect(crop.centerX, inInclusiveRange(0, 1));
    expect(crop.centerY, inInclusiveRange(0, 1));
    expect(crop.scale, 2);

    controller.rotateQuarterTurn();
    crop = container.read(provider);
    expect(crop.rotation, isNot(0));

    controller.reset();
    expect(container.read(provider), CropSpec.centered);
  });

  test('restores the persisted crop when opening an edit session', () {
    final container = ProviderContainer.test();
    final initial = CropSpec(
      centerX: 0.28,
      centerY: 0.71,
      scale: 2.4,
      rotation: 0.5,
    );
    final provider = imageEditorControllerProvider(
      ImageEditorSession(assetId: 'asset-1', initialCropSpec: initial),
    );
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);

    expect(container.read(provider), initial);
  });
}
