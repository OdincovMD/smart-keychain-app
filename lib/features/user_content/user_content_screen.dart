import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../application/user_image_workflow.dart';
import '../../domain/content/scene.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/jewel_button.dart';
import '../device_home/widgets/wardrobe_rail.dart';
import '../image_editor/image_editor_screen.dart';
import '../shared/chrome_kiss_material_sheet.dart';
import '../shared/image_failure_label.dart';
import '../shared/playful_background.dart';
import 'look_details_sheet.dart';
import 'user_content_controller.dart';

enum UserContentScreenResult { addImage }

final class UserContentScreen extends ConsumerStatefulWidget {
  const UserContentScreen({this.highlightedSceneId, super.key});

  final String? highlightedSceneId;

  @override
  ConsumerState<UserContentScreen> createState() => _UserContentScreenState();
}

final class _UserContentScreenState extends ConsumerState<UserContentScreen> {
  late String? _highlightedSceneId = widget.highlightedSceneId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scenes = ref.watch(sceneLibraryProvider);
    final action = ref.watch(userContentControllerProvider);
    final deviceCommand = ref.watch(deviceControllerProvider);
    final snapshot = ref.watch(deviceSnapshotProvider).value;
    final busy =
        action is UserContentLoadingEdit ||
        action is UserContentSaving ||
        action is UserContentDeleting ||
        deviceCommand.isLoading;

    ref.listen(userContentControllerProvider, (previous, next) {
      switch (next) {
        case UserContentEditing(:final draft)
            when previous is! UserContentEditing:
          unawaited(_openEditor(draft));
        case UserContentEditing():
          break;
        case UserContentCompleted(:final operation, :final sceneId):
          if (mounted) {
            if (operation == UserContentOperation.edit) {
              setState(() => _highlightedSceneId = sceneId);
            }
            final message = switch (operation) {
              UserContentOperation.edit => l10n.imageChangesSaved,
              UserContentOperation.delete => l10n.imageDeleted,
            };
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
          ref.read(userContentControllerProvider.notifier).acknowledge();
        case UserContentFailed(:final failure):
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(imageFailureLabel(l10n, failure))),
            );
          }
          ref.read(userContentControllerProvider.notifier).acknowledge();
        case UserContentIdle() ||
            UserContentLoadingEdit() ||
            UserContentSaving() ||
            UserContentDeleting():
          break;
      }
    });
    ref.listen(deviceControllerProvider, (previous, next) {
      if (!mounted || previous?.isLoading != true) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.connectionError)));
      } else if (next.hasValue) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.imageSetAsCurrent)));
      }
    });

    return Scaffold(
      key: const Key('user_content_screen'),
      backgroundColor: context.chromeKiss.canvas,
      body: PlayfulBackground(
        child: SafeArea(
          child: scenes.when(
            data: (items) => _WardrobeCollection(
              scenes: items,
              activeSceneId: snapshot?.activeSceneId,
              highlightedSceneId: _highlightedSceneId,
              enabled: !busy,
              onAddLook: _addImage,
              onOpenLook: (scene) => unawaited(_openLookDetails(scene)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(sceneLibraryProvider),
                child: Text(l10n.retry),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addImage() {
    Navigator.of(context).pop(UserContentScreenResult.addImage);
  }

  Future<void> _openLookDetails(Scene scene) async {
    final action = await showChromeKissMaterialSheet<LookDetailsAction>(
      context: context,
      builder: (context) => LookDetailsSheet(scene: scene),
    );
    if (!mounted) return;
    switch (action) {
      case LookDetailsAction.edit:
        final content = scene.content;
        if (content is UserImageContent) {
          ref
              .read(userContentControllerProvider.notifier)
              .startEdit(content.assetId);
        }
      case LookDetailsAction.delete:
        await _confirmDelete(scene);
      case null:
        break;
    }
  }

  Future<void> _openEditor(UserImageEditDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          key: Key('user_content_editor_${draft.assetId}'),
          assetId: draft.assetId,
          originalBytes: draft.originalBytes,
          initialCropSpec: draft.cropSpec,
          mode: ImageEditorMode.edit,
          onSave: (cropSpec) async {
            final profile = ref
                .read(deviceSnapshotProvider)
                .value
                ?.displayProfile;
            if (profile == null) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.connectionError)));
              }
              return false;
            }
            return ref
                .read(userContentControllerProvider.notifier)
                .saveEdit(cropSpec, profile);
          },
        ),
      ),
    );
    if (!mounted) return;
    if (saved == null) {
      ref.read(userContentControllerProvider.notifier).cancelEdit();
    }
  }

  Future<void> _confirmDelete(Scene scene) async {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final confirmed = await showChromeKissMaterialSheet<bool>(
      context: context,
      isScrollControlled: false,
      builder: (context) => ChromeKissMaterialSheet(
        key: const Key('delete_image_confirmation'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.deleteImageTitle,
              style: context.chromeKissText.title.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.deleteImageMessage,
              style: context.chromeKissText.body.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('cancel_delete_image'),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('confirm_delete_image'),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.danger,
                      foregroundColor: colors.canvas,
                    ),
                    child: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    ref.read(userContentControllerProvider.notifier).deleteScene(scene.id);
  }
}

final class _WardrobeCollection extends StatelessWidget {
  const _WardrobeCollection({
    required this.scenes,
    required this.activeSceneId,
    required this.highlightedSceneId,
    required this.enabled,
    required this.onAddLook,
    required this.onOpenLook,
  });

  final List<Scene> scenes;
  final String? activeSceneId;
  final String? highlightedSceneId;
  final bool enabled;
  final VoidCallback onAddLook;
  final ValueChanged<Scene> onOpenLook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasUserLooks = scenes.any(
      (scene) => scene.source == SceneSource.userGenerated,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final outerPadding = math.max(18.0, (constraints.maxWidth - 620) / 2);
        final gridWidth = constraints.maxWidth - outerPadding * 2;
        final columnCount = gridWidth >= 520 ? 3 : 2;
        const columnGap = 14.0;
        final tileWidth =
            (gridWidth - columnGap * (columnCount - 1)) / columnCount;
        final previewDiameter = math.min(tileWidth, 184.0);
        final scaledLabelLine =
            MediaQuery.textScalerOf(context).scale(13) * 1.28;
        final tileExtent = previewDiameter + scaledLabelLine * 3 + 24;

        return CustomScrollView(
          key: const Key('wardrobe_scroll'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                outerPadding - 6,
                4,
                outerPadding - 6,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('wardrobe_back_button'),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('my_content_add_button'),
                      onPressed: enabled ? onAddLook : null,
                      tooltip: l10n.addImage,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(outerPadding, 8, outerPadding, 26),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myContent,
                      style: context.chromeKissText.title.copyWith(
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.wardrobeIntro,
                      style: context.chromeKissText.body.copyWith(
                        color: context.chromeKiss.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: outerPadding),
              sliver: SliverGrid(
                key: const Key('my_content_list'),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: columnGap,
                  mainAxisSpacing: 10,
                  mainAxisExtent: tileExtent,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: scenes.length + (hasUserLooks ? 1 : 0),
                  (context, index) {
                    final offset = index.isOdd ? 12.0 : 0.0;
                    if (index == scenes.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: offset),
                        child: AddLookTile(
                          key: const Key('wardrobe_add_look_tile'),
                          width: tileWidth,
                          previewDiameter: previewDiameter,
                          enabled: enabled,
                          busy: false,
                          onPressed: onAddLook,
                        ),
                      );
                    }
                    final scene = scenes[index];
                    final isActive = scene.id == activeSceneId;
                    return Padding(
                      padding: EdgeInsets.only(top: offset),
                      child: LookTile(
                        key: Key('my_content_scene_${scene.id}'),
                        scene: scene,
                        width: tileWidth,
                        previewDiameter: previewDiameter,
                        isSelected: isActive,
                        isActive: isActive,
                        isHighlighted: scene.id == highlightedSceneId,
                        enabled: enabled,
                        onSelected: () => onOpenLook(scene),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (!hasUserLooks)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  outerPadding,
                  12,
                  outerPadding,
                  40,
                ),
                sliver: SliverToBoxAdapter(
                  child: _EmptyUserLookSlot(
                    onAddLook: enabled ? onAddLook : null,
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}

final class _EmptyUserLookSlot extends StatelessWidget {
  const _EmptyUserLookSlot({required this.onAddLook});

  final VoidCallback? onAddLook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final colors = context.chromeKiss;
    final copy = Column(
      crossAxisAlignment: largeText
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myContentEmptyTitle,
          textAlign: largeText ? TextAlign.center : TextAlign.start,
          style: context.chromeKissText.label.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.myContentEmptyMessage,
          textAlign: largeText ? TextAlign.center : TextAlign.start,
          style: context.chromeKissText.body.copyWith(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: largeText ? double.infinity : 210,
          child: JewelButton(
            key: const Key('my_content_empty_add_button'),
            label: l10n.addImage,
            onPressed: onAddLook,
          ),
        ),
      ],
    );

    if (largeText) {
      return Column(
        children: [
          const _EmptyLensSlot(diameter: 112),
          const SizedBox(height: 20),
          copy,
        ],
      );
    }
    return Row(
      children: [
        const _EmptyLensSlot(diameter: 112),
        const SizedBox(width: 22),
        Expanded(child: copy),
      ],
    );
  }
}

final class _EmptyLensSlot extends StatelessWidget {
  const _EmptyLensSlot({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).emptyLookPreview,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(diameter),
          painter: _EmptyLensPainter(
            lens: colors.lens,
            chrome: colors.materialChrome,
            optical: colors.accentOptical,
          ),
        ),
      ),
    );
  }
}

final class _EmptyLensPainter extends CustomPainter {
  _EmptyLensPainter({
    required this.lens,
    required this.chrome,
    required this.optical,
  }) : _fill = Paint()..color = lens,
       _edge = Paint()
         ..color = chrome.withValues(alpha: 0.56)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.1,
       _trace = Paint()
         ..color = optical.withValues(alpha: 0.58)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = 2;

  final Color lens;
  final Color chrome;
  final Color optical;
  final Paint _fill;
  final Paint _edge;
  final Paint _trace;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 2;
    canvas.drawCircle(center, radius, _fill);
    canvas.drawCircle(center, radius, _edge);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      math.pi * 1.08,
      math.pi * 0.48,
      false,
      _trace,
    );
    canvas.drawCircle(
      center.translate(radius * 0.26, -radius * 0.18),
      4,
      _trace,
    );
  }

  @override
  bool shouldRepaint(_EmptyLensPainter oldDelegate) {
    return oldDelegate.lens != lens ||
        oldDelegate.chrome != chrome ||
        oldDelegate.optical != optical;
  }
}
