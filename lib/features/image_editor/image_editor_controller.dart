import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/image/crop_spec.dart';

final imageEditorControllerProvider = NotifierProvider.autoDispose
    .family<ImageEditorController, CropSpec, ImageEditorSession>(
      ImageEditorController.new,
    );

final class ImageEditorSession {
  const ImageEditorSession({
    required this.assetId,
    required this.initialCropSpec,
  });

  final String assetId;
  final CropSpec initialCropSpec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageEditorSession &&
          assetId == other.assetId &&
          initialCropSpec == other.initialCropSpec;

  @override
  int get hashCode => Object.hash(assetId, initialCropSpec);
}

final class ImageEditorController extends Notifier<CropSpec> {
  ImageEditorController(this.session);

  final ImageEditorSession session;

  @override
  CropSpec build() => session.initialCropSpec;

  void applyGesture({
    required CropSpec start,
    required double deltaX,
    required double deltaY,
    required double scaleFactor,
  }) {
    final scale = (start.scale * scaleFactor).clamp(
      CropSpec.minScale,
      CropSpec.maxScale,
    );
    state = CropSpec(
      centerX: (start.centerX - deltaX / scale).clamp(0, 1),
      centerY: (start.centerY - deltaY / scale).clamp(0, 1),
      scale: scale,
      rotation: start.rotation,
    );
  }

  void reset() => state = CropSpec.centered;

  void rotateQuarterTurn() {
    var rotation = state.rotation + math.pi / 2;
    if (rotation > math.pi) rotation -= 2 * math.pi;
    state = state.copyWith(rotation: rotation);
  }
}
