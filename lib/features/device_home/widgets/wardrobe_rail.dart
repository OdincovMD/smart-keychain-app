import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/content/scene.dart';
import '../../../l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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

final class LookTile extends StatelessWidget {
  const LookTile({
    required this.scene,
    required this.width,
    required this.previewDiameter,
    required this.isSelected,
    required this.isActive,
    required this.enabled,
    required this.onSelected,
    super.key,
  });

  final Scene scene;
  final double width;
  final double previewDiameter;
  final bool isSelected;
  final bool isActive;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final motion = context.chromeKissMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context);
    final semanticLabel = isActive
        ? '${scene.name}, ${l10n.activeScene}'
        : scene.name;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: InkWell(
            onTap: enabled ? onSelected : null,
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: reduceMotion || isSelected ? 1 : 0.965,
                  duration: reduceMotion
                      ? Duration.zero
                      : motion.interaction.duration,
                  curve: motion.interaction.curve,
                  child: AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : motion.interaction.duration,
                    curve: motion.interaction.curve,
                    width: previewDiameter,
                    height: previewDiameter,
                    padding: EdgeInsets.all(isSelected ? 3 : 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.lens,
                      border: Border.all(
                        color: isSelected
                            ? colors.materialChrome
                            : colors.divider.withValues(alpha: 0.34),
                        width: isSelected ? 1.5 : 0.65,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colors.lens.withValues(alpha: 0.32),
                                blurRadius: 9,
                                spreadRadius: -4,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipOval(
                          child: SceneRenderer(scene: scene, animate: false),
                        ),
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: isSelected ? 1 : 0,
                            duration: reduceMotion
                                ? Duration.zero
                                : motion.interaction.duration,
                            curve: motion.interaction.curve,
                            child: CustomPaint(
                              painter: _LookSelectionTracePainter(
                                colors.accentOptical,
                              ),
                            ),
                          ),
                        ),
                        if (isActive)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: colors.lens,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.materialChrome,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: colors.accentOptical,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scene.name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.chromeKissText.body.copyWith(
                    color: isSelected
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

final class AddLookTile extends StatelessWidget {
  const AddLookTile({
    required this.width,
    required this.previewDiameter,
    required this.enabled,
    required this.busy,
    required this.onPressed,
    super.key,
  });

  final double width;
  final double previewDiameter;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
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
            borderRadius: BorderRadius.circular(18),
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
                          padding: const EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: colors.materialChrome,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.add_rounded,
                          color: colors.textPrimary,
                          size: 27,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.addImage,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.chromeKissText.body.copyWith(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.28,
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
