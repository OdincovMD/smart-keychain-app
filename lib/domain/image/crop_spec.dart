import 'dart:math' as math;

final class CropSpec {
  factory CropSpec({
    required double centerX,
    required double centerY,
    required double scale,
    required double rotation,
  }) {
    if (!centerX.isFinite || centerX < 0 || centerX > 1) {
      throw RangeError.value(centerX, 'centerX', 'Must be between 0 and 1.');
    }
    if (!centerY.isFinite || centerY < 0 || centerY > 1) {
      throw RangeError.value(centerY, 'centerY', 'Must be between 0 and 1.');
    }
    if (!scale.isFinite || scale < minScale || scale > maxScale) {
      throw RangeError.value(scale, 'scale', 'Must be between 1 and 8.');
    }
    if (!rotation.isFinite || rotation < -math.pi || rotation > math.pi) {
      throw RangeError.value(
        rotation,
        'rotation',
        'Must be between -pi and pi.',
      );
    }
    return CropSpec._(
      centerX: centerX,
      centerY: centerY,
      scale: scale,
      rotation: rotation,
    );
  }

  const CropSpec._({
    required this.centerX,
    required this.centerY,
    required this.scale,
    required this.rotation,
  });

  static const minScale = 1.0;
  static const maxScale = 8.0;
  static const centered = CropSpec._(
    centerX: 0.5,
    centerY: 0.5,
    scale: 1,
    rotation: 0,
  );

  final double centerX;
  final double centerY;
  final double scale;
  final double rotation;

  CropSpec copyWith({
    double? centerX,
    double? centerY,
    double? scale,
    double? rotation,
  }) {
    return CropSpec(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropSpec &&
          centerX == other.centerX &&
          centerY == other.centerY &&
          scale == other.scale &&
          rotation == other.rotation;

  @override
  int get hashCode => Object.hash(centerX, centerY, scale, rotation);
}
