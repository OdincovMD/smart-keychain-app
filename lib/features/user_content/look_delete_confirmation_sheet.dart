import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/content/scene.dart';
import '../device_home/widgets/jewel_button.dart';
import '../device_home/widgets/chrome_kiss_production_eyes.dart';
import '../device_home/widgets/kiss_cut_eye_renderer.dart';
import '../shared/chrome_kiss_material_sheet.dart';
import 'user_content_controller.dart';

final class LookDeleteConfirmationSheet extends ConsumerWidget {
  const LookDeleteConfirmationSheet({required this.scene, super.key});

  final Scene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(userContentControllerProvider);
    final deleting = switch (action) {
      UserContentDeleting(:final sceneId) when sceneId == scene.id => true,
      _ => false,
    };
    final failed = action is UserContentFailed;

    ref.listen(userContentControllerProvider, (previous, next) {
      if (next
          case UserContentCompleted(
            operation: UserContentOperation.delete,
            :final sceneId,
          )
          when sceneId == scene.id) {
        ref.read(userContentControllerProvider.notifier).acknowledge();
        Navigator.of(context).pop(true);
      }
    });

    return PopScope(
      canPop: !deleting,
      child: ChromeKissMaterialSheet(
        key: const Key('delete_image_confirmation'),
        child: _DeleteContent(
          scene: scene,
          deleting: deleting,
          failed: failed,
          onKeep: deleting
              ? null
              : () {
                  if (failed) {
                    ref
                        .read(userContentControllerProvider.notifier)
                        .acknowledge();
                  }
                  Navigator.of(context).pop(false);
                },
          onDelete: deleting
              ? null
              : () {
                  final controller = ref.read(
                    userContentControllerProvider.notifier,
                  );
                  if (failed) controller.acknowledge();
                  controller.deleteScene(scene.id);
                },
        ),
      ),
    );
  }
}

final class _DeleteContent extends StatelessWidget {
  const _DeleteContent({
    required this.scene,
    required this.deleting,
    required this.failed,
    required this.onKeep,
    required this.onDelete,
  });

  final Scene scene;
  final bool deleting;
  final bool failed;
  final VoidCallback? onKeep;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final fidelity = context.chromeKissFidelity;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'УДАЛЕНИЕ ОБРАЗА',
            textAlign: TextAlign.center,
            style: context.chromeKissText.status.copyWith(
              color: colors.danger,
              letterSpacing: 1.05,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Удалить этот образ',
            textAlign: TextAlign.center,
            style: context.chromeKissText.title.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fidelity.controlSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: fidelity.chromeLine),
            ),
            child: Row(
              children: [
                Container(
                  key: const Key('delete_look_preview'),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: fidelity.lens,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.accentPrimary, width: 2),
                  ),
                  child: const Center(
                    child: ChromeKissProductionEyes(
                      scale: ChromeKissEyeScale.tiny,
                      mood: KissCutVisualMood.annoyed,
                      animate: false,
                      useProductionMotion: false,
                    ),
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
                        style: context.chromeKissText.label,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Мой образ · Личное фото',
                        style: context.chromeKissText.body.copyWith(
                          color: fidelity.mutedInk,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.danger.withValues(alpha: 0.42)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Образ и сохранённое фото будут удалены без возможности восстановления.',
                    style: context.chromeKissText.body.copyWith(
                      color: fidelity.mutedInk,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (failed) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Container(
                key: const Key('delete_look_error'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.danger),
                ),
                child: Text(
                  'Удалить образ не удалось. Он остался в коллекции — попробуйте ещё раз.',
                  style: context.chromeKissText.body.copyWith(
                    color: colors.danger,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          JewelButton(
            key: const Key('cancel_delete_image'),
            label: 'Оставить образ',
            style: JewelButtonStyle.hero,
            onPressed: onKeep,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('confirm_delete_image'),
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: colors.danger,
              side: BorderSide(color: colors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: deleting
                ? SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.danger,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(
              deleting
                  ? 'Удаляем…'
                  : failed
                  ? 'Попробовать удалить снова'
                  : 'Удалить навсегда',
            ),
          ),
        ],
      ),
    );
  }
}
