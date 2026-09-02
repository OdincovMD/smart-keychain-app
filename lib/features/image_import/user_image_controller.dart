import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../application/user_image_workflow.dart';
import '../../core/result.dart';
import '../../domain/device/display_profile.dart';
import '../../domain/image/crop_spec.dart';
import '../../domain/image/user_image_failure.dart';
import '../../infrastructure/content/user_image_scene_repository.dart';

sealed class UserImageFlowState {
  const UserImageFlowState();
}

final class UserImageIdle extends UserImageFlowState {
  const UserImageIdle();
}

final class UserImagePicking extends UserImageFlowState {
  const UserImagePicking();
}

final class UserImageEditing extends UserImageFlowState {
  const UserImageEditing(this.draft);

  final PendingUserImage draft;
}

final class UserImageSaving extends UserImageFlowState {
  const UserImageSaving();
}

final class UserImageCompleted extends UserImageFlowState {
  const UserImageCompleted(this.sceneId);

  final String sceneId;
}

final class UserImageFailed extends UserImageFlowState {
  const UserImageFailed(this.failure);

  final UserImageFailure failure;
}

final userImageControllerProvider =
    NotifierProvider.autoDispose<UserImageController, UserImageFlowState>(
      UserImageController.new,
    );

final class UserImageController extends Notifier<UserImageFlowState> {
  @override
  UserImageFlowState build() => const UserImageIdle();

  void startImport() {
    if (state is! UserImageIdle) return;
    unawaited(_startImport());
  }

  void save(CropSpec cropSpec, DisplayProfile targetProfile) {
    final current = state;
    if (current is! UserImageEditing) return;
    unawaited(_save(current.draft, cropSpec, targetProfile));
  }

  void cancel() {
    final current = state;
    if (current is! UserImageEditing) return;
    state = const UserImageSaving();
    unawaited(_discard(current.draft));
  }

  void acknowledge() {
    if (state is UserImageCompleted || state is UserImageFailed) {
      state = const UserImageIdle();
    }
  }

  Future<void> _startImport() async {
    state = const UserImagePicking();
    final outcome = await ref.read(userImageWorkflowProvider).beginImport();
    if (!ref.mounted) return;
    state = switch (outcome) {
      UserImageImportReady(:final draft) => UserImageEditing(draft),
      UserImageImportCancelled() => const UserImageIdle(),
      UserImageImportFailed(:final failure) => UserImageFailed(failure),
    };
  }

  Future<void> _save(
    PendingUserImage draft,
    CropSpec cropSpec,
    DisplayProfile targetProfile,
  ) async {
    state = const UserImageSaving();
    final result = await ref
        .read(userImageWorkflowProvider)
        .completeImport(
          draft: draft,
          cropSpec: cropSpec,
          targetProfile: targetProfile,
        );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        ref.invalidate(sceneLibraryProvider);
        final sceneId = UserImageSceneRepository.sceneIdForAsset(value.id);
        ref.invalidate(sceneByIdProvider(sceneId));
        state = UserImageCompleted(sceneId);
      case Err(:final failure):
        state = UserImageFailed(failure);
    }
  }

  Future<void> _discard(PendingUserImage draft) async {
    final result = await ref.read(userImageWorkflowProvider).discard(draft);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const UserImageIdle(),
      Err(:final failure) => UserImageFailed(failure),
    };
  }
}
