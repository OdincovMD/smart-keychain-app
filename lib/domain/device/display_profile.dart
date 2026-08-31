enum DisplayShape { circle }

final class DisplayProfile {
  const DisplayProfile({
    required this.width,
    required this.height,
    required this.shape,
    required this.aspectRatio,
  });

  final int width;
  final int height;
  final DisplayShape shape;
  final double aspectRatio;

  DisplayProfile copyWith({
    int? width,
    int? height,
    DisplayShape? shape,
    double? aspectRatio,
  }) {
    return DisplayProfile(
      width: width ?? this.width,
      height: height ?? this.height,
      shape: shape ?? this.shape,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayProfile &&
          width == other.width &&
          height == other.height &&
          shape == other.shape &&
          aspectRatio == other.aspectRatio;

  @override
  int get hashCode => Object.hash(width, height, shape, aspectRatio);
}
