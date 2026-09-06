import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../application/user_image_workflow.dart';
import '../../core/result.dart';
import '../../domain/content/scene.dart';
import '../../domain/device/display_profile.dart';
import '../../domain/image/crop_spec.dart';
import '../../domain/image/user_image_failure.dart';
import '../../infrastructure/content/user_image_scene_repository.dart';

enum UserContentOperation { edit, delete }

sealed class UserContentActionState {
  const UserContentActionState();
}

final class UserContentIdle extends UserContentActionState {
  const UserContentIdle();

  @override
  bool operator ==(Object other) => other is UserContentIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class UserContentLoadingEdit extends UserContentActionState {
  const UserContentLoadingEdit(this.assetId);

  final String assetId;

  @override
  bool operator ==(Object other) =>
      other is UserContentLoadingEdit && assetId == other.assetId;

  @override
  int get hashCode => Object.hash(runtimeType, assetId);
}

final class UserContentEditing extends UserContentActionState {
  const UserContentEditing(this.draft);

  final UserImageEditDraft draft;

  @override
  bool operator ==(Object other) =>
      other is UserContentEditing && draft == other.draft;

  @override
  int get hashCode => Object.hash(runtimeType, draft);
}

final class UserContentSaving extends UserContentActionState {
  const UserContentSaving(this.sceneId);

  final String sceneId;

  @override
  bool operator ==(Object other) =>
      other is UserContentSaving && sceneId == other.sceneId;

  @override
  int get hashCode => Object.hash(runtimeType, sceneId);
}

final class UserContentDeleting extends UserContentActionState {
  const UserContentDeleting(this.sceneId);

  final String sceneId;

  @override
  bool operator ==(Object other) =>
      other is UserContentDeleting && sceneId == other.sceneId;

  @override
  int get hashCode => Object.hash(runtimeType, sceneId);
}

final class UserContentCompleted extends UserContentActionState {
  const UserContentCompleted({required this.operation, required this.sceneId});

  final UserContentOperation operation;
  final String sceneId;

  @override
  bool operator ==(Object other) =>
      other is UserContentCompleted &&
      operation == other.operation &&
      sceneId == other.sceneId;

  @override
  int get hashCode => Object.hash(runtimeType, operation, sceneId);
}

final class UserContentFailed extends UserContentActionState {
  const UserContentFailed(this.failure);

  final UserImageFailure failure;

  @override
  bool operator ==(Object other) =>
      other is UserContentFailed && failure.code == other.failure.code;

  @override
  int get hashCode => Object.hash(runtimeType, failure.code);
}

final myContentScenesProvider = FutureProvider.autoDispose<List<Scene>>((
  ref,
) async {
  final scenes = await ref.watch(sceneLibraryProvider.future);
  return List.unmodifiable(
    scenes.where(
      (scene) =>
          scene.source == SceneSource.userGenerated &&
          scene.content is UserImageContent,
    ),
  );
});

final userContentControllerProvider =
    NotifierProvider.autoDispose<UserContentController, UserContentActionState>(
      UserContentController.new,
    );

final class UserContentController extends Notifier<UserContentActionState> {
  @override
  UserContentActionState build() => const UserContentIdle();

  void startEdit(String assetId) {
    if (state is! UserContentIdle) return;
    state = UserContentLoadingEdit(assetId);
    unawaited(_loadForEdit(assetId));
  }

  void saveEdit(CropSpec cropSpec, DisplayProfile targetProfile) {
    final current = state;
    if (current is! UserContentEditing) return;
    final sceneId = UserImageSceneRepository.sceneIdForAsset(
      current.draft.assetId,
    );
    state = UserContentSaving(sceneId);
    unawaited(
      _saveEdit(
        draft: current.draft,
        cropSpec: cropSpec,
        targetProfile: targetProfile,
        sceneId: sceneId,
      ),
    );
  }

  void cancelEdit() {
    if (state is UserContentEditing) state = const UserContentIdle();
  }

  void deleteScene(String sceneId) {
    if (state is! UserContentIdle) return;
    state = UserContentDeleting(sceneId);
    unawaited(_deleteScene(sceneId));
  }

  void acknowledge() {
    if (state is UserContentCompleted || state is UserContentFailed) {
      state = const UserContentIdle();
    }
  }

  Future<void> _loadForEdit(String assetId) async {
    final result = await ref
        .read(userImageWorkflowProvider)
        .loadForEdit(assetId);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => UserContentEditing(value),
      Err(:final failure) => UserContentFailed(failure),
    };
  }

  Future<void> _saveEdit({
    required UserImageEditDraft draft,
    required CropSpec cropSpec,
    required DisplayProfile targetProfile,
    required String sceneId,
  }) async {
    final result = await ref
        .read(userImageWorkflowProvider)
        .updateCrop(
          assetId: draft.assetId,
          cropSpec: cropSpec,
          targetProfile: targetProfile,
        );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        ref.invalidate(sceneLibraryProvider);
        ref.invalidate(sceneByIdProvider(sceneId));
        ref.invalidate(localImageBytesProvider(value.previewStorageKey));
        state = UserContentCompleted(
          operation: UserContentOperation.edit,
          sceneId: sceneId,
        );
      case Err(:final failure):
        state = UserContentFailed(failure);
    }
  }

  Future<void> _deleteScene(String sceneId) async {
    final result = await ref.read(deleteUserImageSceneProvider)(sceneId);
    if (!ref.mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(sceneLibraryProvider);
        ref.invalidate(sceneByIdProvider(sceneId));
        ref.invalidate(localImageBytesProvider);
        state = UserContentCompleted(
          operation: UserContentOperation.delete,
          sceneId: sceneId,
        );
      case Err(:final failure):
        state = UserContentFailed(failure);
    }
  }
}
