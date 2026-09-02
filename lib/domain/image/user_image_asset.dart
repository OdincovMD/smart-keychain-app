import 'crop_spec.dart';

final class UserImageAsset {
  UserImageAsset({
    required this.id,
    required this.originalStorageKey,
    required this.previewStorageKey,
    required this.cropSpec,
    required DateTime createdAt,
  }) : createdAt = createdAt.toUtc() {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'Must not be empty.');
    if (originalStorageKey.isEmpty) {
      throw ArgumentError.value(
        originalStorageKey,
        'originalStorageKey',
        'Must not be empty.',
      );
    }
    if (previewStorageKey.isEmpty) {
      throw ArgumentError.value(
        previewStorageKey,
        'previewStorageKey',
        'Must not be empty.',
      );
    }
  }

  final String id;
  final String originalStorageKey;
  final String previewStorageKey;
  final CropSpec cropSpec;
  final DateTime createdAt;

  UserImageAsset copyWith({
    String? originalStorageKey,
    String? previewStorageKey,
    CropSpec? cropSpec,
  }) {
    return UserImageAsset(
      id: id,
      originalStorageKey: originalStorageKey ?? this.originalStorageKey,
      previewStorageKey: previewStorageKey ?? this.previewStorageKey,
      cropSpec: cropSpec ?? this.cropSpec,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserImageAsset &&
          id == other.id &&
          originalStorageKey == other.originalStorageKey &&
          previewStorageKey == other.previewStorageKey &&
          cropSpec == other.cropSpec &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    originalStorageKey,
    previewStorageKey,
    cropSpec,
    createdAt,
  );
}
