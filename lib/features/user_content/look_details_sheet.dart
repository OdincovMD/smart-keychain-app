import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../domain/content/scene.dart';
import '../shared/chrome_kiss_material_sheet.dart';
import 'look_application_controller.dart';
import 'look_application_view.dart';
import 'look_details_ready.dart';

enum LookDetailsAction { edit, delete }

final class LookDetailsSheet extends ConsumerWidget {
  const LookDetailsSheet({required this.scene, super.key});

  final Scene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref.watch(lookApplicationControllerProvider(scene.id));
    final snapshotState = ref.watch(deviceSnapshotProvider);
    final snapshot = snapshotState.value;
    final snapshotReady = snapshotState.hasValue;
    final isActive = snapshot?.activeSceneId == scene.id;
    final isUserLook = scene.source == SceneSource.userGenerated;
    final applying = application.status == LookApplicationStatus.applying;
    final lifecycle = application.status != LookApplicationStatus.ready;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = switch (application.status) {
      LookApplicationStatus.ready => LookDetailsReady(
        scene: scene,
        isActive: isActive,
        onClose: () => Navigator.of(context).pop(),
        onApply: isActive || !snapshotReady
            ? null
            : () => ref
                  .read(lookApplicationControllerProvider(scene.id).notifier)
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
        scene: scene,
        status: application.status,
        onRetry: () => ref
            .read(lookApplicationControllerProvider(scene.id).notifier)
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
}
