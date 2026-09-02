import '../eyes/eye_emotion.dart';

enum SceneType { proceduralEyes, staticImage, userImage }

enum SceneSource { builtIn, userGenerated }

sealed class SceneContent {
  const SceneContent();

  SceneType get type;

  bool get animated;
}

final class StaticImageContent extends SceneContent {
  const StaticImageContent({required this.previewAssetPath});

  final String previewAssetPath;

  @override
  SceneType get type => SceneType.staticImage;

  @override
  bool get animated => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticImageContent && previewAssetPath == other.previewAssetPath;

  @override
  int get hashCode => previewAssetPath.hashCode;
}

final class ProceduralEyesContent extends SceneContent {
  const ProceduralEyesContent({required this.defaultEmotion});

  final EyeEmotion defaultEmotion;

  @override
  SceneType get type => SceneType.proceduralEyes;

  @override
  bool get animated => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProceduralEyesContent && defaultEmotion == other.defaultEmotion;

  @override
  int get hashCode => defaultEmotion.hashCode;
}

final class UserImageContent extends SceneContent {
  const UserImageContent({
    required this.assetId,
    required this.previewStorageKey,
  });

  final String assetId;
  final String previewStorageKey;

  @override
  SceneType get type => SceneType.userImage;

  @override
  bool get animated => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserImageContent &&
          assetId == other.assetId &&
          previewStorageKey == other.previewStorageKey;

  @override
  int get hashCode => Object.hash(assetId, previewStorageKey);
}

final class Scene {
  const Scene({
    required this.id,
    required this.name,
    required this.content,
    required this.source,
    this.description,
    this.tags = const {},
  });

  final String id;
  final String name;
  final String? description;
  final SceneContent content;
  final SceneSource source;
  final Set<String> tags;

  SceneType get type => content.type;

  bool get animated => content.animated;

  Scene copyWith({
    String? id,
    String? name,
    String? description,
    SceneContent? content,
    SceneSource? source,
    Set<String>? tags,
  }) {
    return Scene(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      source: source ?? this.source,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Scene &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          content == other.content &&
          source == other.source &&
          _setEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    content,
    source,
    Object.hashAllUnordered(tags),
  );
}

bool _setEquals(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);
