enum SceneType { staticImage }

enum SceneSource { builtIn }

final class Scene {
  const Scene({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.previewAssetId,
    required this.type,
    required this.source,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final String previewAssetId;
  final SceneType type;
  final SceneSource source;

  Scene copyWith({
    String? id,
    String? titleKey,
    String? descriptionKey,
    String? previewAssetId,
    SceneType? type,
    SceneSource? source,
  }) {
    return Scene(
      id: id ?? this.id,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      previewAssetId: previewAssetId ?? this.previewAssetId,
      type: type ?? this.type,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Scene &&
          id == other.id &&
          titleKey == other.titleKey &&
          descriptionKey == other.descriptionKey &&
          previewAssetId == other.previewAssetId &&
          type == other.type &&
          source == other.source;

  @override
  int get hashCode =>
      Object.hash(id, titleKey, descriptionKey, previewAssetId, type, source);
}
