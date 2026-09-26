import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/content/scene.dart';
import '../../../l10n/app_localizations.dart';
import 'companion_home_tokens.dart';
import 'scene_renderer.dart';

final class WardrobeRail extends StatelessWidget {
  const WardrobeRail({
    required this.scenes,
    required this.selectedSceneId,
    required this.activeSceneId,
    required this.enabled,
    required this.isAddingImage,
    required this.onSceneSelected,
    required this.onOpenAll,
    required this.onAddImage,
    this.compact = false,
    super.key,
  });

  final List<Scene> scenes;
  final String selectedSceneId;
  final String activeSceneId;
  final bool enabled;
  final bool isAddingImage;
  final ValueChanged<String> onSceneSelected;
  final VoidCallback onOpenAll;
  final VoidCallback onAddImage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (compact) {
      return _CompactWardrobeRail(
        scenes: scenes,
        selectedSceneId: selectedSceneId,
        activeSceneId: activeSceneId,
        enabled: enabled,
        isAddingImage: isAddingImage,
        onSceneSelected: onSceneSelected,
        onOpenAll: onOpenAll,
        onAddImage: onAddImage,
      );
    }

    return Column(
      key: const Key('wardrobe_rail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.wardrobe,
                style: context.chromeKissText.title.copyWith(
                  fontSize: 18,
                  letterSpacing: -0.25,
                ),
              ),
            ),
            IconButton(
              key: const Key('add_user_image_button'),
              onPressed: enabled ? onAddImage : null,
              tooltip: l10n.addImage,
              icon: isAddingImage
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded, size: 21),
            ),
            TextButton.icon(
              key: const Key('open_all_looks_button'),
              onPressed: onOpenAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(l10n.allLooks),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = math.min(
              116.0,
              math.max(86.0, (constraints.maxWidth - 20) / 2.72),
            );
            final previewDiameter = tileWidth * 0.88;
            final labelHeight =
                MediaQuery.textScalerOf(context).scale(13) * 1.28 * 3 + 4;
            final railHeight = previewDiameter + 8 + labelHeight;

            return SizedBox(
              height: railHeight,
              child: ListView.separated(
                key: const Key('wardrobe_list'),
                scrollDirection: Axis.horizontal,
                scrollCacheExtent: const ScrollCacheExtent.pixels(140),
                itemCount: scenes.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == scenes.length) {
                    return AddLookTile(
                      width: tileWidth,
                      previewDiameter: previewDiameter,
                      enabled: enabled,
                      busy: isAddingImage,
                      onPressed: onAddImage,
                    );
                  }
                  final scene = scenes[index];
                  return LookTile(
                    key: Key('scene_${scene.id}'),
                    scene: scene,
                    width: tileWidth,
                    previewDiameter: previewDiameter,
                    isSelected: scene.id == selectedSceneId,
                    isActive: scene.id == activeSceneId,
                    enabled: enabled,
                    onSelected: () => onSceneSelected(scene.id),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

final class _CompactWardrobeRail extends StatelessWidget {
  const _CompactWardrobeRail({
    required this.scenes,
    required this.selectedSceneId,
    required this.activeSceneId,
    required this.enabled,
    required this.isAddingImage,
    required this.onSceneSelected,
    required this.onOpenAll,
    required this.onAddImage,
  });

  final List<Scene> scenes;
  final String selectedSceneId;
  final String activeSceneId;
  final bool enabled;
  final bool isAddingImage;
  final ValueChanged<String> onSceneSelected;
  final VoidCallback onOpenAll;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final home = context.companionHome;
    final visibleScenes = scenes.take(3).toList(growable: false);
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 16;

    return Column(
      key: const Key('wardrobe_rail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (largeText) ...[
          Text(
            l10n.myContent,
            style: context.chromeKissText.body.copyWith(
              color: home.textPrimary,
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('open_all_looks_button'),
              onPressed: onOpenAll,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: colors.accentPrimary,
                textStyle: context.chromeKissText.status.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(l10n.allLooks),
                  const Icon(Icons.arrow_forward_rounded, size: 13),
                ],
              ),
            ),
          ),
        ] else
          SizedBox(
            height: 26,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.myContent,
                    style: context.chromeKissText.body.copyWith(
                      color: home.textPrimary,
                      fontSize: 18,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const Key('open_all_looks_button'),
                  onPressed: onOpenAll,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    foregroundColor: colors.accentPrimary,
                    textStyle: context.chromeKissText.status.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                  label: Text(l10n.allLooks),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final scaledLabelSize = MediaQuery.textScalerOf(context).scale(10);
            final tileWidth = scaledLabelSize > 13
                ? math.max(74.0, scaledLabelSize * 6.8)
                : math.min(74.0, (constraints.maxWidth - gap * 3) / 4);
            final previewDiameter = math.min(58.0, tileWidth);
            final labelHeight =
                MediaQuery.textScalerOf(context).scale(11) * 1.27 * 2 + 1;
            final previewGap = scaledLabelSize > 13 ? 5.0 : 2.0;

            return SizedBox(
              height: previewDiameter + previewGap + labelHeight,
              child: ListView.separated(
                key: const Key('wardrobe_list'),
                scrollDirection: Axis.horizontal,
                physics: scaledLabelSize > 13
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: visibleScenes.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  if (index == visibleScenes.length) {
                    return AddLookTile(
                      key: const Key('add_user_image_button'),
                      width: tileWidth,
                      previewDiameter: previewDiameter,
                      enabled: enabled,
                      busy: isAddingImage,
                      onPressed: onAddImage,
                      compact: true,
                    );
                  }
                  final scene = visibleScenes[index];
                  return LookTile(
                    key: Key('scene_${scene.id}'),
                    scene: scene,
                    width: tileWidth,
                    previewDiameter: previewDiameter,
                    isSelected: scene.id == selectedSceneId,
                    isActive: scene.id == activeSceneId,
                    enabled: enabled,
                    onSelected: () => onSceneSelected(scene.id),
                    compact: true,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

final class LookTile extends StatelessWidget {
  const LookTile({
    required this.scene,
    required this.width,
    required this.previewDiameter,
    required this.isSelected,
    required this.isActive,
    required this.enabled,
    required this.onSelected,
    this.isHighlighted = false,
    this.compact = false,
    this.labelOverride,
    this.compactPreviewAssetPath,
    super.key,
  });

  final Scene scene;
  final double width;
  final double previewDiameter;
  final bool isSelected;
  final bool isActive;
  final bool isHighlighted;
  final bool enabled;
  final VoidCallback onSelected;
  final bool compact;
  final String? labelOverride;
  final String? compactPreviewAssetPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final home = context.companionHome;
    final motion = context.chromeKissMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context);
    final semanticLabel = switch ((isActive, isHighlighted)) {
      (true, _) => '${scene.name}, ${l10n.activeScene}',
      (false, true) => '${scene.name}, ${l10n.lookSaved}',
      _ => scene.name,
    };

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected || isHighlighted,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: InkWell(
            onTap: enabled ? onSelected : null,
            borderRadius: BorderRadius.circular(compact ? 8 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: compact || reduceMotion || isSelected || isHighlighted
                      ? 1
                      : 0.965,
                  duration: reduceMotion
                      ? Duration.zero
                      : motion.interaction.duration,
                  curve: motion.interaction.curve,
                  child: LookPreview(
                    scene: scene,
                    diameter: previewDiameter,
                    isSelected: isSelected || isHighlighted,
                    isActive: isActive,
                    isHighlighted: isHighlighted,
                    compact: compact,
                    compactPreviewAssetPath: compactPreviewAssetPath,
                  ),
                ),
                SizedBox(
                  height: compact
                      ? MediaQuery.textScalerOf(context).scale(11) > 14
                            ? 5
                            : 2
                      : 8,
                ),
                Text(
                  labelOverride ?? scene.name,
                  textAlign: TextAlign.center,
                  style: context.chromeKissText.body.copyWith(
                    color: compact
                        ? home.textPrimary
                        : isSelected
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontSize: compact ? 11 : 13,
                    height: compact ? 1.27 : 1.28,
                    fontWeight: compact || !isSelected
                        ? FontWeight.w500
                        : FontWeight.w700,
                    letterSpacing: compact ? 0 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class LookPreview extends StatelessWidget {
  const LookPreview({
    required this.scene,
    required this.diameter,
    required this.isSelected,
    required this.isActive,
    this.animateScene = false,
    this.isHighlighted = false,
    this.compact = false,
    this.compactPreviewAssetPath,
    super.key,
  });

  final Scene scene;
  final double diameter;
  final bool isSelected;
  final bool isActive;
  final bool animateScene;
  final bool isHighlighted;
  final bool compact;
  final String? compactPreviewAssetPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final motion = context.chromeKissMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (compactPreviewAssetPath != null) {
      return _FigmaHomeLookImage(
        diameter: diameter,
        assetPath: compactPreviewAssetPath!,
        sourceDimension: 75,
      );
    }

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : motion.interaction.duration,
      curve: motion.interaction.curve,
      width: diameter,
      height: diameter,
      padding: EdgeInsets.all(isSelected ? (compact ? 2 : 3) : 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.lens,
        border: Border.all(
          color: isSelected
              ? compact
                    ? colors.accentPrimary
                    : colors.materialChrome
              : colors.divider.withValues(alpha: 0.34),
          width: isSelected ? (compact ? 2 : 1.5) : 0.65,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: compact
                      ? colors.accentPrimary.withValues(alpha: 0.34)
                      : colors.lens.withValues(alpha: 0.32),
                  blurRadius: compact ? 12 : 9,
                  spreadRadius: compact ? -2 : -4,
                  offset: Offset(0, compact ? 0 : 5),
                ),
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipOval(
            child: SceneRenderer(scene: scene, animate: animateScene),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: reduceMotion
                  ? Duration.zero
                  : motion.interaction.duration,
              curve: motion.interaction.curve,
              child: CustomPaint(
                painter: _LookSelectionTracePainter(colors.accentOptical),
              ),
            ),
          ),
          if (isActive && !compact)
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: diameter < 120 ? 25 : 32,
                height: diameter < 120 ? 25 : 32,
                decoration: BoxDecoration(
                  color: colors.lens,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.materialChrome),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: diameter < 120 ? 15 : 19,
                  color: colors.accentOptical,
                ),
              ),
            ),
          if (isHighlighted && !isActive)
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                key: const Key('look_saved_marker'),
                width: diameter < 120 ? 25 : 32,
                height: diameter < 120 ? 25 : 32,
                decoration: BoxDecoration(
                  color: colors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.materialChrome),
                ),
                child: Icon(
                  Icons.done_rounded,
                  size: diameter < 120 ? 15 : 19,
                  color: colors.lens,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class AddLookTile extends StatelessWidget {
  const AddLookTile({
    required this.width,
    required this.previewDiameter,
    required this.enabled,
    required this.busy,
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  final double width;
  final double previewDiameter;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final home = context.companionHome;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: l10n.addImage,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(compact ? 8 : 18),
            child: Column(
              children: [
                Container(
                  width: previewDiameter,
                  height: previewDiameter,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      colors.surfaceSecondary.withValues(alpha: 0.72),
                      colors.canvas,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.materialChrome.withValues(alpha: 0.62),
                      width: 0.9,
                    ),
                  ),
                  child: busy
                      ? Padding(
                          padding: EdgeInsets.all(compact ? 18 : 24),
                          child: CircularProgressIndicator(
                            color: colors.materialChrome,
                            strokeWidth: 2,
                          ),
                        )
                      : compact
                      ? const _FigmaHomeLookImage(
                          diameter: 58,
                          assetPath: 'assets/chrome_kiss/home_look_photo.png',
                          sourceDimension: 58,
                        )
                      : Icon(
                          Icons.add_rounded,
                          color: colors.textPrimary,
                          size: 27,
                        ),
                ),
                SizedBox(
                  height: compact
                      ? MediaQuery.textScalerOf(context).scale(11) > 14
                            ? 5
                            : 2
                      : 8,
                ),
                Text(
                  compact ? l10n.homeLookPhoto : l10n.addImage,
                  textAlign: TextAlign.center,
                  style: context.chromeKissText.body.copyWith(
                    color: compact ? home.textPrimary : colors.textSecondary,
                    fontSize: compact ? 11 : 13,
                    height: compact ? 1.27 : 1.28,
                    fontWeight: compact ? FontWeight.w500 : null,
                    letterSpacing: compact ? 0 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FigmaHomeLookImage extends StatelessWidget {
  const _FigmaHomeLookImage({
    required this.diameter,
    required this.assetPath,
    required this.sourceDimension,
  });

  final double diameter;
  final String assetPath;
  final double sourceDimension;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: ClipOval(
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: sourceDimension,
          maxWidth: sourceDimension,
          minHeight: sourceDimension,
          maxHeight: sourceDimension,
          child: Image.asset(
            assetPath,
            width: sourceDimension,
            height: sourceDimension,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

final class _LookSelectionTracePainter extends CustomPainter {
  _LookSelectionTracePainter(this.color)
    : _paint = Paint()
        ..color = color.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.1;

  final Color color;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 1.6;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.02,
      math.pi * 0.42,
      false,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_LookSelectionTracePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
