import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/content/scene.dart';
import '../../../domain/device/display_profile.dart';
import 'kiss_cut_eye_renderer.dart';
import 'procedural_eyes_view.dart';

final class SceneRenderer extends ConsumerWidget {
  const SceneRenderer({
    required this.scene,
    required this.animate,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.displayProfile,
    super.key,
  });

  final Scene scene;
  final bool animate;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final DisplayProfile? displayProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (scene.content) {
      final StaticImageContent content => StaticImageSceneRenderer(
        content: content,
        fit: fit,
        filterQuality: filterQuality,
      ),
      final ProceduralEyesContent content => ProceduralEyesSceneRenderer(
        content: content,
        animate: animate,
        displayProfile: displayProfile,
      ),
      final UserImageContent content => UserImageSceneRenderer(
        content: content,
        fit: fit,
        filterQuality: filterQuality,
      ),
    };
  }
}

final class UserImageSceneRenderer extends ConsumerWidget {
  const UserImageSceneRenderer({
    required this.content,
    required this.fit,
    required this.filterQuality,
    super.key,
  });

  final UserImageContent content;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(localImageBytesProvider(content.previewStorageKey));
    return bytes.when(
      data: (value) => value == null
          ? const _MissingUserImage()
          : Image.memory(
              value,
              fit: fit,
              filterQuality: filterQuality,
              cacheWidth: 240,
              gaplessPlayback: true,
            ),
      loading: () => const ColoredBox(color: Colors.black),
      error: (error, stackTrace) => const _MissingUserImage(),
    );
  }
}

final class _MissingUserImage extends StatelessWidget {
  const _MissingUserImage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54),
      ),
    );
  }
}

final class StaticImageSceneRenderer extends StatelessWidget {
  const StaticImageSceneRenderer({
    required this.content,
    required this.fit,
    required this.filterQuality,
    super.key,
  });

  final StaticImageContent content;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      content.previewAssetPath,
      fit: fit,
      filterQuality: filterQuality,
    );
  }
}

final class ProceduralEyesSceneRenderer extends StatelessWidget {
  const ProceduralEyesSceneRenderer({
    required this.content,
    required this.animate,
    this.displayProfile,
    super.key,
  });

  final ProceduralEyesContent content;
  final bool animate;
  final DisplayProfile? displayProfile;

  @override
  Widget build(BuildContext context) {
    return ProceduralEyesView(
      initialEmotion: content.defaultEmotion,
      animate: animate,
      displayProfile: displayProfile,
      rendererVariant: EyeRendererVariant.kissCutV21,
      useProductionMotionDefinition: animate,
    );
  }
}
