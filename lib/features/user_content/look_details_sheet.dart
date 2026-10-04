import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../domain/content/scene.dart';
import '../shared/chrome_kiss_material_sheet.dart';
import '../device_home/widgets/eye_motion_ticker.dart';
import 'look_application_controller.dart';
import 'look_application_view.dart';
import 'look_details_ready.dart';
import 'look_eye_reaction_coordinator.dart';

enum LookDetailsAction { edit, delete }

final class LookDetailsSheet extends ConsumerStatefulWidget {
  const LookDetailsSheet({required this.scene, this.eyeRuntime, super.key});

  final Scene scene;
  final EyeMotionTicker? eyeRuntime;

  @override
  ConsumerState<LookDetailsSheet> createState() => _LookDetailsSheetState();
}

final class _LookDetailsSheetState extends ConsumerState<LookDetailsSheet> {
  LookEyeReactionCoordinator? _reactionCoordinator;

  @override
  void initState() {
    super.initState();
    _replaceCoordinator();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncReaction(
      ref.read(lookApplicationControllerProvider(widget.scene.id)).status,
    );
  }

  @override
  void didUpdateWidget(LookDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.eyeRuntime, widget.eyeRuntime)) {
      _reactionCoordinator?.dispose();
      _replaceCoordinator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationProvider = lookApplicationControllerProvider(
      widget.scene.id,
    );
    final application = ref.watch(applicationProvider);
    ref.listen(
      applicationProvider.select((state) => state.status),
      (previous, next) => _syncReaction(next),
    );
    final snapshotState = ref.watch(deviceSnapshotProvider);
    final snapshot = snapshotState.value;
    final snapshotReady = snapshotState.hasValue;
    final isActive = snapshot?.activeSceneId == widget.scene.id;
    final isUserLook = widget.scene.source == SceneSource.userGenerated;
    final applying = application.status == LookApplicationStatus.applying;
    final lifecycle = application.status != LookApplicationStatus.ready;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = switch (application.status) {
      LookApplicationStatus.ready => LookDetailsReady(
        scene: widget.scene,
        isActive: isActive,
        onClose: () => Navigator.of(context).pop(),
        onApply: isActive || !snapshotReady
            ? null
            : () => ref
                  .read(
                    lookApplicationControllerProvider(widget.scene.id).notifier,
                  )
                  .apply(),
        onEdit: isUserLook
            ? () => Navigator.of(context).pop(LookDetailsAction.edit)
            : null,
        onDelete: isUserLook
            ? () => Navigator.of(context).pop(LookDetailsAction.delete)
            : null,
      ),
      LookApplicationStatus.applying ||
      LookApplicationStatus.applied ||
      LookApplicationStatus.failed => LookApplicationView(
        scene: widget.scene,
        status: application.status,
        eyeRuntime: widget.eyeRuntime,
        onRetry: () => ref
            .read(lookApplicationControllerProvider(widget.scene.id).notifier)
            .retry(),
        onReturn: () => Navigator.of(context).pop(),
      ),
    };

    return PopScope(
      canPop: !applying,
      child: ChromeKissMaterialSheet(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: lifecycle
                ? MediaQuery.sizeOf(context).height - 64
                : MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: reduceMotion
                  ? content
                  : AnimatedSize(
                      duration: context.chromeKissMotion.transition.duration,
                      curve: context.chromeKissMotion.transition.curve,
                      alignment: Alignment.bottomCenter,
                      child: content,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _replaceCoordinator() {
    final runtime = widget.eyeRuntime;
    _reactionCoordinator = runtime == null
        ? null
        : LookEyeReactionCoordinator(
            player: runtime.player,
            refresh: runtime.refresh,
          );
  }

  void _syncReaction(LookApplicationStatus status) {
    _reactionCoordinator?.sync(
      status,
      reducedMotion: MediaQuery.disableAnimationsOf(context),
    );
  }

  @override
  void dispose() {
    _reactionCoordinator?.dispose();
    super.dispose();
  }
}
