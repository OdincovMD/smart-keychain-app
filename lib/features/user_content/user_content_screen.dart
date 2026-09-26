import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../application/user_image_workflow.dart';
import '../../domain/content/scene.dart';
import '../../infrastructure/content/built_in_scene_repository.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/chrome_kiss_bottom_navigation.dart';
import '../device_home/widgets/scene_renderer.dart';
import '../device_home/widgets/wardrobe_rail.dart';
import '../image_editor/image_editor_screen.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';
import '../shared/chrome_kiss_fidelity_tokens.dart';
import '../shared/chrome_kiss_material_sheet.dart';
import '../shared/image_failure_label.dart';
import 'look_delete_confirmation_sheet.dart';
import 'look_details_sheet.dart';
import 'user_content_controller.dart';
import 'wardrobe_states.dart';

enum UserContentScreenResult { addImage }

final class UserContentScreen extends ConsumerStatefulWidget {
  const UserContentScreen({this.highlightedSceneId, super.key});

  final String? highlightedSceneId;

  @override
  ConsumerState<UserContentScreen> createState() => _UserContentScreenState();
}

final class _UserContentScreenState extends ConsumerState<UserContentScreen> {
  late String? _highlightedSceneId = widget.highlightedSceneId;
  var _showPhotosOnly = false;
  var _deleteSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
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
        case UserContentCompleted(operation: UserContentOperation.delete)
            when _deleteSheetOpen:
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
        case UserContentFailed() when _deleteSheetOpen:
          break;
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
    return Scaffold(
      key: const Key('user_content_screen'),
      backgroundColor: fidelity.outside,
      body: ChromeKissFidelityFrame(
        child: scenes.when(
          data: (items) => _WardrobeCollection(
            scenes: items,
            loadState: _WardrobeLoadState.ready,
            activeSceneId: snapshot?.activeSceneId,
            highlightedSceneId: _highlightedSceneId,
            enabled: !busy,
            showPhotosOnly: _showPhotosOnly,
            onShowPhotosOnlyChanged: (value) {
              setState(() => _showPhotosOnly = value);
            },
            onBack: () => Navigator.of(context).pop(),
            onAddLook: _addImage,
            onOpenLook: (scene) => unawaited(_openLookDetails(scene)),
          ),
          loading: () => _WardrobeCollection(
            scenes: const [],
            loadState: _WardrobeLoadState.loading,
            activeSceneId: snapshot?.activeSceneId,
            highlightedSceneId: _highlightedSceneId,
            enabled: false,
            showPhotosOnly: _showPhotosOnly,
            onShowPhotosOnlyChanged: (value) {
              setState(() => _showPhotosOnly = value);
            },
            onBack: () => Navigator.of(context).pop(),
            onAddLook: _addImage,
            onOpenLook: (_) {},
          ),
          error: (error, stackTrace) => _WardrobeCollection(
            scenes: const [],
            loadState: _WardrobeLoadState.error,
            activeSceneId: snapshot?.activeSceneId,
            highlightedSceneId: _highlightedSceneId,
            enabled: false,
            showPhotosOnly: _showPhotosOnly,
            onShowPhotosOnlyChanged: (value) {
              setState(() => _showPhotosOnly = value);
            },
            onBack: () => Navigator.of(context).pop(),
            onAddLook: _addImage,
            onOpenLook: (_) {},
            onRetry: () => ref.invalidate(sceneLibraryProvider),
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
      isDismissible: false,
      enableDrag: false,
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
    _deleteSheetOpen = true;
    await showChromeKissMaterialSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => LookDeleteConfirmationSheet(scene: scene),
    );
    if (!mounted) return;
    _deleteSheetOpen = false;
  }
}

enum _WardrobeLoadState { ready, loading, error }

final class _WardrobeCollection extends StatelessWidget {
  const _WardrobeCollection({
    required this.scenes,
    required this.loadState,
    required this.activeSceneId,
    required this.highlightedSceneId,
    required this.enabled,
    required this.showPhotosOnly,
    required this.onShowPhotosOnlyChanged,
    required this.onBack,
    required this.onAddLook,
    required this.onOpenLook,
    this.onRetry,
  });

  final List<Scene> scenes;
  final _WardrobeLoadState loadState;
  final String? activeSceneId;
  final String? highlightedSceneId;
  final bool enabled;
  final bool showPhotosOnly;
  final ValueChanged<bool> onShowPhotosOnlyChanged;
  final VoidCallback onBack;
  final VoidCallback onAddLook;
  final ValueChanged<Scene> onOpenLook;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final exact =
            constraints.maxWidth >= 380 &&
            constraints.maxHeight >= 844 &&
            textScale <= 1.15 &&
            MediaQuery.viewPaddingOf(context) == EdgeInsets.zero;
        return exact
            ? _WardrobeReferenceLayout(
                scenes: scenes,
                loadState: loadState,
                activeSceneId: activeSceneId,
                highlightedSceneId: highlightedSceneId,
                enabled: enabled,
                showPhotosOnly: showPhotosOnly,
                onShowPhotosOnlyChanged: onShowPhotosOnlyChanged,
                onBack: onBack,
                onAddLook: onAddLook,
                onOpenLook: onOpenLook,
                onRetry: onRetry,
              )
            : _WardrobeAdaptiveLayout(
                scenes: scenes,
                loadState: loadState,
                activeSceneId: activeSceneId,
                highlightedSceneId: highlightedSceneId,
                enabled: enabled,
                showPhotosOnly: showPhotosOnly,
                onShowPhotosOnlyChanged: onShowPhotosOnlyChanged,
                onBack: onBack,
                onAddLook: onAddLook,
                onOpenLook: onOpenLook,
                onRetry: onRetry,
              );
      },
    );
  }
}

final class _WardrobeReferenceLayout extends StatelessWidget {
  const _WardrobeReferenceLayout({
    required this.scenes,
    required this.loadState,
    required this.activeSceneId,
    required this.highlightedSceneId,
    required this.enabled,
    required this.showPhotosOnly,
    required this.onShowPhotosOnlyChanged,
    required this.onBack,
    required this.onAddLook,
    required this.onOpenLook,
    this.onRetry,
  });

  final List<Scene> scenes;
  final _WardrobeLoadState loadState;
  final String? activeSceneId;
  final String? highlightedSceneId;
  final bool enabled;
  final bool showPhotosOnly;
  final ValueChanged<bool> onShowPhotosOnlyChanged;
  final VoidCallback onBack;
  final VoidCallback onAddLook;
  final ValueChanged<Scene> onOpenLook;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final active = _sceneById(scenes, activeSceneId) ?? scenes.firstOrNull;
    final tiles = _wardrobeTiles(scenes, photosOnly: showPhotosOnly);
    final hasUserLooks = scenes.any(
      (scene) => scene.source == SceneSource.userGenerated,
    );
    final showEmpty =
        loadState == _WardrobeLoadState.ready &&
        showPhotosOnly &&
        !hasUserLooks;
    return SingleChildScrollView(
      key: const Key('wardrobe_scroll'),
      child: SizedBox(
        height: ChromeKissFidelityTokens.referenceSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: _WardrobeAtmosphere()),
            const Positioned.fill(child: _WardrobeCornerVeil()),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ChromeKissReferenceStatusBar(),
            ),
            Positioned(
              left: 24,
              top: 51,
              child: Text(l10n.wardrobe, style: fidelity.titleStyle),
            ),
            Positioned(
              left: 25,
              top: 87,
              child: ChromeKissScriptHeartText(text: l10n.wardrobeAccent),
            ),
            Positioned(
              left: 24,
              top: 122,
              child: _WardrobeTabs(
                photosOnly: showPhotosOnly,
                onChanged: onShowPhotosOnlyChanged,
              ),
            ),
            if (loadState == _WardrobeLoadState.loading)
              Positioned(
                right: 24,
                top: 64,
                child: Text(
                  l10n.wardrobeLoadingStatus,
                  style: context.chromeKissText.status.copyWith(
                    color: fidelity.accentInk,
                    fontSize: 9,
                    letterSpacing: 0,
                  ),
                ),
              ),
            if (showEmpty)
              Positioned(
                right: 24,
                top: 64,
                child: Text(
                  l10n.wardrobeEmptyCount,
                  style: context.chromeKissText.status.copyWith(
                    color: fidelity.mutedInk,
                    fontSize: 9,
                    letterSpacing: 0,
                  ),
                ),
              ),
            if (loadState == _WardrobeLoadState.loading)
              const Positioned(
                left: 24,
                top: 178,
                child: WardrobeLoadingState(
                  key: Key('wardrobe_loading_state'),
                  referenceLayout: true,
                ),
              )
            else if (loadState == _WardrobeLoadState.error)
              Positioned(
                left: 24,
                top: 178,
                width: 345,
                height: 548,
                child: WardrobeErrorState(
                  key: const Key('wardrobe_error_state'),
                  onRetry: onRetry!,
                ),
              )
            else if (showEmpty)
              Positioned(
                left: 24,
                top: 183,
                child: WardrobeEmptyState(
                  key: const Key('wardrobe_empty_state'),
                  referenceLayout: true,
                  onCreate: onAddLook,
                ),
              )
            else if (active != null)
              Positioned(
                left: 24,
                top: 178,
                child: _CurrentLookCard(
                  scene: active,
                  enabled: enabled,
                  adaptive: false,
                  onPressed: () => onOpenLook(active),
                ),
              ),
            if (loadState == _WardrobeLoadState.ready && !showEmpty) ...[
              Positioned(
                left: 24,
                top: 355,
                child: Text(
                  showPhotosOnly ? l10n.wardrobePhotosTab : l10n.myContent,
                  style: TextStyle(
                    color: fidelity.ink,
                    fontFamily: 'Manrope',
                    fontSize: 17,
                    height: 24 / 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 386,
                child: _WardrobeGrid(
                  scenes: tiles,
                  referenceLayout: true,
                  activeSceneId: activeSceneId,
                  highlightedSceneId: highlightedSceneId,
                  enabled: enabled,
                  hasUserLooks: hasUserLooks,
                  onAddLook: onAddLook,
                  onOpenLook: onOpenLook,
                ),
              ),
            ],
            Positioned(
              left: 14,
              top: 752,
              width: 365,
              child: ChromeKissBottomNavigation(
                selectedDestination: ChromeKissNavDestination.looks,
                selectedForeground: fidelity.specular,
                onHome: onBack,
                onLooks: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WardrobeAdaptiveLayout extends StatelessWidget {
  const _WardrobeAdaptiveLayout({
    required this.scenes,
    required this.loadState,
    required this.activeSceneId,
    required this.highlightedSceneId,
    required this.enabled,
    required this.showPhotosOnly,
    required this.onShowPhotosOnlyChanged,
    required this.onBack,
    required this.onAddLook,
    required this.onOpenLook,
    this.onRetry,
  });

  final List<Scene> scenes;
  final _WardrobeLoadState loadState;
  final String? activeSceneId;
  final String? highlightedSceneId;
  final bool enabled;
  final bool showPhotosOnly;
  final ValueChanged<bool> onShowPhotosOnlyChanged;
  final VoidCallback onBack;
  final VoidCallback onAddLook;
  final ValueChanged<Scene> onOpenLook;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final active = _sceneById(scenes, activeSceneId) ?? scenes.firstOrNull;
    final tiles = _wardrobeTiles(scenes, photosOnly: showPhotosOnly);
    final hasUserLooks = scenes.any(
      (scene) => scene.source == SceneSource.userGenerated,
    );
    final showEmpty =
        loadState == _WardrobeLoadState.ready &&
        showPhotosOnly &&
        !hasUserLooks;
    return CustomScrollView(
      key: const Key('wardrobe_scroll'),
      slivers: [
        const SliverToBoxAdapter(child: ChromeKissReferenceStatusBar()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          sliver: SliverList.list(
            children: [
              Text(l10n.wardrobe, style: fidelity.titleStyle),
              ChromeKissScriptHeartText(text: l10n.wardrobeAccent),
              const SizedBox(height: 12),
              _WardrobeTabs(
                photosOnly: showPhotosOnly,
                onChanged: onShowPhotosOnlyChanged,
              ),
              const SizedBox(height: 12),
              if (loadState == _WardrobeLoadState.loading)
                const WardrobeLoadingState(
                  key: Key('wardrobe_loading_state'),
                  referenceLayout: false,
                )
              else if (loadState == _WardrobeLoadState.error)
                SizedBox(
                  height: 500,
                  child: WardrobeErrorState(
                    key: const Key('wardrobe_error_state'),
                    onRetry: onRetry!,
                  ),
                )
              else if (showEmpty)
                WardrobeEmptyState(
                  key: const Key('wardrobe_empty_state'),
                  referenceLayout: false,
                  onCreate: onAddLook,
                )
              else ...[
                if (active != null)
                  Center(
                    child: _CurrentLookCard(
                      scene: active,
                      enabled: enabled,
                      adaptive: true,
                      onPressed: () => onOpenLook(active),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(showPhotosOnly ? l10n.wardrobePhotosTab : l10n.myContent),
                const SizedBox(height: 8),
                Center(
                  child: _WardrobeGrid(
                    scenes: tiles,
                    referenceLayout: false,
                    activeSceneId: activeSceneId,
                    highlightedSceneId: highlightedSceneId,
                    enabled: enabled,
                    hasUserLooks: hasUserLooks,
                    onAddLook: onAddLook,
                    onOpenLook: onOpenLook,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ChromeKissBottomNavigation(
                selectedDestination: ChromeKissNavDestination.looks,
                selectedForeground: fidelity.specular,
                onHome: onBack,
                onLooks: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _WardrobeAtmosphere extends StatelessWidget {
  const _WardrobeAtmosphere();

  @override
  Widget build(BuildContext context) {
    final opacity = context.chromeKissFidelity.atmosphereOpacity;
    return Opacity(
      opacity: opacity,
      child: const Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Image(
              image: AssetImage('assets/chrome_kiss/wardrobe_pearl_blush.png'),
              width: 117,
              height: 190,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Image(
              image: AssetImage('assets/chrome_kiss/wardrobe_lilac_blush.png'),
              width: 125,
              height: 220,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

final class _WardrobeCornerVeil extends StatelessWidget {
  const _WardrobeCornerVeil();

  @override
  Widget build(BuildContext context) {
    final opacity = context.chromeKissFidelity.atmosphereOpacity;
    return Opacity(
      opacity: opacity,
      child: const Stack(
        children: [
          Positioned(
            right: 0,
            top: 111,
            child: Image(
              image: AssetImage('assets/chrome_kiss/wardrobe_blush_veil.png'),
              width: 134,
              height: 122,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

final class _WardrobeTabs extends StatelessWidget {
  const _WardrobeTabs({required this.photosOnly, required this.onChanged});

  final bool photosOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
    final width = math.min(345.0, MediaQuery.sizeOf(context).width - 48);
    final referenceLayout =
        MediaQuery.sizeOf(context).width >= 380 &&
        MediaQuery.sizeOf(context).height >= 844 &&
        !largeText &&
        MediaQuery.viewPaddingOf(context) == EdgeInsets.zero;
    return Container(
      width: width,
      height: largeText ? 72 : 44,
      decoration: BoxDecoration(
        color: fidelity.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fidelity.chromeLine),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: _WardrobeTab(
                  key: const Key('wardrobe_looks_tab'),
                  label: l10n.wardrobeLooksTab,
                  showHeart: true,
                  selected: !photosOnly,
                  onPressed: () => onChanged(false),
                ),
              ),
              Expanded(
                child: _WardrobeTab(
                  key: const Key('wardrobe_photos_tab'),
                  label: l10n.wardrobePhotosTab,
                  showHeart: false,
                  selected: photosOnly,
                  onPressed: () => onChanged(true),
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            left: referenceLayout
                ? (photosOnly ? 236 : 63)
                : (photosOnly ? 236 : 63) * width / 345,
            bottom: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fidelity.accentInk,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
              child: const SizedBox(width: 44, height: 3),
            ),
          ),
        ],
      ),
    );
  }
}

final class _WardrobeTab extends StatelessWidget {
  const _WardrobeTab({
    required this.label,
    required this.showHeart,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool showHeart;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
    final fidelity = context.chromeKissFidelity;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: largeText
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? fidelity.ink : fidelity.mutedInk,
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    if (showHeart) ...[
                      const SizedBox(width: 2),
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 12,
                        color: fidelity.ink,
                      ),
                    ],
                  ],
                ),
              )
            : Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? fidelity.ink : fidelity.mutedInk,
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (showHeart) ...[
                      const SizedBox(width: 2),
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 12,
                        color: fidelity.ink,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

final class _CurrentLookCard extends StatelessWidget {
  const _CurrentLookCard({
    required this.scene,
    required this.enabled,
    required this.adaptive,
    required this.onPressed,
  });

  final Scene scene;
  final bool enabled;
  final bool adaptive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final width = math.min(345.0, MediaQuery.sizeOf(context).width - 48);
    if (adaptive) {
      return Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: fidelity.satinGradient,
          border: Border.all(color: fidelity.chromeLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CurrentLookPreview(scene: scene),
            const SizedBox(height: 8),
            Text(
              l10n.wardrobeOnDevice,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fidelity.mutedInk,
                fontFamily: 'Manrope',
                fontSize: 11,
                height: 15 / 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _sceneLabel(l10n, scene),
              textAlign: TextAlign.center,
              style: fidelity.titleStyle.copyWith(
                fontSize: 26,
                height: 32 / 26,
              ),
            ),
            ChromeKissScriptHeartText(
              text: l10n.wardrobeCurrentLookMeta,
              fontSize: 19,
              centered: true,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 6,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fidelity.controlSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: fidelity.chromeLine),
                  ),
                  child: Text(
                    l10n.wardrobeWorn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fidelity.accentInk,
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      height: 15 / 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  enabled: enabled,
                  label: _sceneLabel(l10n, scene),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Material(
                      color: fidelity.lens,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const Key('wardrobe_current_look_button'),
                        customBorder: const CircleBorder(),
                        onTap: enabled ? onPressed : null,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: fidelity.lacquer,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Container(
      width: width,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: fidelity.satinGradient,
        border: Border.all(color: fidelity.chromeLine),
      ),
      child: Stack(
        children: [
          Positioned(left: 0, top: 7, child: _CurrentLookPreview(scene: scene)),
          const Positioned(
            left: 101,
            top: 10,
            child: Image(
              image: AssetImage('assets/chrome_kiss/wardrobe_glossy_bow.png'),
              width: 42,
              height: 30,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            left: 149,
            top: 22,
            child: Text(
              l10n.wardrobeOnDevice,
              style: TextStyle(
                color: fidelity.mutedInk,
                fontFamily: 'Manrope',
                fontSize: 11,
                height: 15 / 11,
              ),
            ),
          ),
          Positioned(
            left: 149,
            top: 47,
            child: Text(
              _sceneLabel(l10n, scene),
              style: fidelity.titleStyle.copyWith(
                fontSize: 26,
                height: 32 / 26,
              ),
            ),
          ),
          Positioned(
            left: 149,
            top: 80,
            child: ChromeKissScriptHeartText(
              text: l10n.wardrobeCurrentLookMeta,
              fontSize: 19,
            ),
          ),
          Positioned(
            left: 149,
            top: 111,
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fidelity.controlSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: fidelity.chromeLine),
              ),
              child: Text(
                l10n.wardrobeWorn,
                style: TextStyle(
                  color: fidelity.accentInk,
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  height: 15 / 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 103,
            child: Semantics(
              button: true,
              enabled: enabled,
              label: _sceneLabel(l10n, scene),
              child: SizedBox.square(
                dimension: 44,
                child: Material(
                  color: fidelity.lens,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: const Key('wardrobe_current_look_button'),
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onPressed : null,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: fidelity.lacquer,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _CurrentLookPreview extends StatelessWidget {
  const _CurrentLookPreview({required this.scene});

  final Scene scene;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      height: 147,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Image(
            image: AssetImage('assets/chrome_kiss/wardrobe_jewelry_halo.png'),
            width: 143,
            height: 146,
            filterQuality: FilterQuality.high,
          ),
          LookPreview(
            scene: scene,
            diameter: 102,
            isSelected: false,
            isActive: false,
          ),
        ],
      ),
    );
  }
}

final class _WardrobeGrid extends StatelessWidget {
  const _WardrobeGrid({
    required this.scenes,
    required this.referenceLayout,
    required this.activeSceneId,
    required this.highlightedSceneId,
    required this.enabled,
    required this.hasUserLooks,
    required this.onAddLook,
    required this.onOpenLook,
  });

  final List<Scene> scenes;
  final bool referenceLayout;
  final String? activeSceneId;
  final String? highlightedSceneId;
  final bool enabled;
  final bool hasUserLooks;
  final VoidCallback onAddLook;
  final ValueChanged<Scene> onOpenLook;

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[
      for (final scene in scenes)
        _WardrobeTile(
          key: Key('my_content_scene_${scene.id}'),
          scene: scene,
          referenceLayout: referenceLayout,
          selected: scene.id == activeSceneId,
          highlighted: scene.id == highlightedSceneId,
          enabled: enabled,
          onPressed: () => onOpenLook(scene),
        ),
      _AddWardrobeTile(
        referenceLayout: referenceLayout,
        enabled: enabled,
        hasUserLooks: hasUserLooks,
        onPressed: onAddLook,
      ),
    ];
    if (referenceLayout) {
      return SizedBox(
        key: const Key('my_content_list'),
        width: 345,
        child: Wrap(spacing: 35, runSpacing: 35, children: entries),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return SizedBox(
          key: const Key('my_content_list'),
          width: constraints.maxWidth,
          child: Wrap(
            spacing: spacing,
            runSpacing: 16,
            children: [
              for (final entry in entries)
                SizedBox(width: tileWidth, child: entry),
            ],
          ),
        );
      },
    );
  }
}

final class _WardrobeTile extends StatelessWidget {
  const _WardrobeTile({
    required this.scene,
    required this.referenceLayout,
    required this.selected,
    required this.highlighted,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final Scene scene;
  final bool referenceLayout;
  final bool selected;
  final bool highlighted;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final adaptiveHeight = math.max(
      178.0,
      142 + MediaQuery.textScalerOf(context).scale(18) * 2,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: _sceneLabel(l10n, scene),
      child: SizedBox(
        width: 155,
        height: referenceLayout ? 149 : adaptiveHeight,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Column(
              children: [
                Container(
                  width: 132,
                  height: 103,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: fidelity.satinGradient,
                    border: Border.all(color: fidelity.chromeLine),
                  ),
                  child: _WardrobeTilePreview(
                    scene: scene,
                    highlighted: highlighted,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _sceneLabel(l10n, scene),
                  textAlign: TextAlign.center,
                  maxLines: referenceLayout ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fidelity.ink,
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
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

final class _WardrobeTilePreview extends StatelessWidget {
  const _WardrobeTilePreview({required this.scene, required this.highlighted});

  final Scene scene;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 74,
          height: 74,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: fidelity.chromeLine, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: fidelity.shadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SceneRenderer(scene: scene, animate: false),
        ),
        if (highlighted)
          Positioned(
            right: -2,
            bottom: -2,
            child: DecoratedBox(
              key: Key('look_saved_marker'),
              decoration: BoxDecoration(
                color: fidelity.lacquer,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 22,
                child: Icon(
                  Icons.done_rounded,
                  color: fidelity.specular,
                  size: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _AddWardrobeTile extends StatelessWidget {
  const _AddWardrobeTile({
    required this.referenceLayout,
    required this.enabled,
    required this.hasUserLooks,
    required this.onPressed,
  });

  final bool referenceLayout;
  final bool enabled;
  final bool hasUserLooks;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final adaptiveHeight = math.max(
      178.0,
      142 + MediaQuery.textScalerOf(context).scale(18) * 2,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: l10n.addImage,
      child: SizedBox(
        key: const Key('wardrobe_add_look_tile'),
        width: 155,
        height: referenceLayout ? 149 : adaptiveHeight,
        child: InkWell(
          key: hasUserLooks
              ? const Key('my_content_add_button')
              : const Key('my_content_empty_add_button'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Column(
              children: [
                Container(
                  width: 132,
                  height: 103,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: fidelity.satinGradient,
                    border: Border.all(color: fidelity.chromeLine),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: fidelity.accentInk,
                    size: 31,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  l10n.addLookShort,
                  textAlign: referenceLayout ? null : TextAlign.center,
                  maxLines: referenceLayout ? null : 2,
                  overflow: referenceLayout ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fidelity.ink,
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
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

List<Scene> _wardrobeTiles(List<Scene> scenes, {required bool photosOnly}) {
  final userScenes = scenes
      .where((scene) => scene.source == SceneSource.userGenerated)
      .toList();
  if (photosOnly) return userScenes;
  final builtIns = <Scene>[];
  for (final id in [
    BuiltInSceneRepository.livingEyesId,
    BuiltInSceneRepository.mintEyesId,
  ]) {
    final scene = _sceneById(scenes, id);
    if (scene != null) builtIns.add(scene);
  }
  return [...builtIns, ...userScenes.take(1)];
}

Scene? _sceneById(List<Scene> scenes, String? id) {
  for (final scene in scenes) {
    if (scene.id == id) return scene;
  }
  return null;
}

String _sceneLabel(AppLocalizations l10n, Scene scene) {
  return switch (scene.id) {
    BuiltInSceneRepository.livingEyesId => l10n.homeLookOriginal,
    BuiltInSceneRepository.mintEyesId => l10n.homeLookMint,
    _ when scene.source == SceneSource.userGenerated => l10n.homeLookPhoto,
    _ => scene.name,
  };
}
