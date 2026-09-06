import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_colors.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../application/user_image_workflow.dart';
import '../../domain/content/scene.dart';
import '../../domain/image/crop_spec.dart';
import '../../l10n/app_localizations.dart';
import '../device_home/widgets/scene_renderer.dart';
import '../image_editor/image_editor_screen.dart';
import '../shared/image_failure_label.dart';
import '../shared/playful_background.dart';
import 'user_content_controller.dart';

enum UserContentScreenResult { addImage }

final class UserContentScreen extends ConsumerStatefulWidget {
  const UserContentScreen({super.key});

  @override
  ConsumerState<UserContentScreen> createState() => _UserContentScreenState();
}

final class _UserContentScreenState extends ConsumerState<UserContentScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scenes = ref.watch(myContentScenesProvider);
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
        case UserContentCompleted(:final operation):
          if (mounted) {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.myContent),
        actions: [
          IconButton(
            key: const Key('my_content_add_button'),
            onPressed: busy ? null : _addImage,
            tooltip: l10n.addImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
        ],
      ),
      body: PlayfulBackground(
        child: SafeArea(
          top: false,
          child: scenes.when(
            data: (items) => items.isEmpty
                ? _EmptyUserContent(onAddImage: busy ? null : _addImage)
                : ListView.separated(
                    key: const Key('my_content_list'),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final scene = items[index];
                      final content = scene.content as UserImageContent;
                      return _UserContentCard(
                        scene: scene,
                        isActive: scene.id == snapshot?.activeSceneId,
                        enabled: !busy,
                        onSetCurrent: () => ref
                            .read(deviceControllerProvider.notifier)
                            .setScene(scene.id),
                        onEdit: () => ref
                            .read(userContentControllerProvider.notifier)
                            .startEdit(content.assetId),
                        onDelete: () => unawaited(_confirmDelete(scene)),
                      );
                    },
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

  Future<void> _openEditor(UserImageEditDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final cropSpec = await Navigator.of(context).push<CropSpec>(
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          key: Key('user_content_editor_${draft.assetId}'),
          assetId: draft.assetId,
          originalBytes: draft.originalBytes,
          initialCropSpec: draft.cropSpec,
        ),
      ),
    );
    if (!mounted) return;
    if (cropSpec == null) {
      ref.read(userContentControllerProvider.notifier).cancelEdit();
      return;
    }
    final profile = ref.read(deviceSnapshotProvider).value?.displayProfile;
    if (profile == null) {
      ref.read(userContentControllerProvider.notifier).cancelEdit();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.connectionError)));
      return;
    }
    ref
        .read(userContentControllerProvider.notifier)
        .saveEdit(cropSpec, profile);
  }

  Future<void> _confirmDelete(Scene scene) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('delete_image_confirmation'),
        title: Text(l10n.deleteImageTitle),
        content: Text(l10n.deleteImageMessage),
        actions: [
          TextButton(
            key: const Key('cancel_delete_image'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_image'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    ref.read(userContentControllerProvider.notifier).deleteScene(scene.id);
  }
}

final class _EmptyUserContent extends StatelessWidget {
  const _EmptyUserContent({required this.onAddImage});

  final VoidCallback? onAddImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: AppColors.mint,
              ),
              const SizedBox(height: 18),
              Text(
                l10n.myContentEmptyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.myContentEmptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('my_content_empty_add_button'),
                onPressed: onAddImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(l10n.addImage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _UserContentCard extends StatelessWidget {
  const _UserContentCard({
    required this.scene,
    required this.isActive,
    required this.enabled,
    required this.onSetCurrent,
    required this.onEdit,
    required this.onDelete,
  });

  final Scene scene;
  final bool isActive;
  final bool enabled;
  final VoidCallback onSetCurrent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: Key('my_content_scene_${scene.id}'),
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 78,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SceneRenderer(scene: scene, animate: false),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive ? l10n.activeScene : l10n.userImage,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive ? AppColors.mint : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  key: Key('set_current_${scene.id}'),
                  onPressed: enabled && !isActive ? onSetCurrent : null,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(isActive ? l10n.installed : l10n.setAsCurrent),
                ),
                IconButton(
                  key: Key('edit_${scene.id}'),
                  onPressed: enabled ? onEdit : null,
                  tooltip: l10n.editCrop,
                  icon: const Icon(Icons.crop_rounded),
                ),
                IconButton(
                  key: Key('delete_${scene.id}'),
                  onPressed: enabled ? onDelete : null,
                  tooltip: l10n.delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
