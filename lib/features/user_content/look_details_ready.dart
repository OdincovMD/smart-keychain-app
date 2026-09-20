import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/content/scene.dart';
import '../device_home/widgets/jewel_button.dart';
import '../device_home/widgets/wardrobe_rail.dart';

final class LookDetailsReady extends StatelessWidget {
  const LookDetailsReady({
    required this.scene,
    required this.isActive,
    required this.onClose,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Scene scene;
  final bool isActive;
  final VoidCallback onClose;
  final VoidCallback? onApply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    final colors = context.chromeKiss;
    final source = scene.source == SceneSource.userGenerated
        ? 'Мой образ'
        : 'Встроенный';
    final type = switch (scene.type) {
      SceneType.proceduralEyes => 'Живой взгляд',
      SceneType.staticImage => 'Статичный образ',
      SceneType.userImage => 'Личное фото',
    };

    return SingleChildScrollView(
      key: const Key('look_details_scroll'),
      child: Column(
        key: const Key('look_details_state_ready'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ДЕТАЛИ ОБРАЗА',
                      style: context.chromeKissText.status.copyWith(
                        color: fidelity.accentInk,
                        letterSpacing: 0.88,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scene.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.chromeKissText.title.copyWith(
                        fontSize: 31,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'Закрыть детали образа',
                child: IconButton(
                  key: const Key('close_look_details'),
                  onPressed: onClose,
                  tooltip: 'Закрыть',
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: fidelity.controlSurface,
                    side: BorderSide(color: fidelity.chromeLine),
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: fidelity.ink,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label:
                '$source, ${scene.name}, $type. '
                '${isActive ? 'Сейчас на брелоке' : 'Сейчас не надет'}',
            child: ExcludeSemantics(
              child: Container(
                key: const Key('look_details_preview_card'),
                constraints: const BoxConstraints(minHeight: 104),
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                decoration: BoxDecoration(
                  color: fidelity.controlSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: fidelity.chromeLine),
                ),
                child: Row(
                  children: [
                    LookPreview(
                      key: const Key('look_details_preview'),
                      scene: scene,
                      diameter: 82,
                      isSelected: true,
                      isActive: isActive,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scene.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.chromeKissText.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$source · $type',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.chromeKissText.body.copyWith(
                              color: fidelity.mutedInk,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 14,
                                color: isActive
                                    ? colors.success
                                    : fidelity.accentInk,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  isActive
                                      ? 'Сейчас на брелоке'
                                      : 'Сейчас не надет',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.chromeKissText.status.copyWith(
                                    color: isActive
                                        ? colors.success
                                        : fidelity.accentInk,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            key: const Key('look_details_traits'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final trait in _traitsFor(scene)) _LookTrait(label: trait),
            ],
          ),
          const SizedBox(height: 12),
          JewelButton(
            key: Key('set_current_${scene.id}'),
            label: isActive ? 'Уже надет' : 'Надеть образ',
            style: JewelButtonStyle.hero,
            onPressed: onApply,
          ),
          if (onEdit != null && onDelete != null) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackActions =
                    constraints.maxWidth < 330 ||
                    MediaQuery.textScalerOf(context).scale(12) > 18;
                final edit = _SecondaryAction(
                  key: Key('edit_${scene.id}'),
                  label: 'Редактировать',
                  onPressed: onEdit!,
                );
                final delete = _SecondaryAction(
                  key: Key('delete_${scene.id}'),
                  label: 'Удалить',
                  onPressed: onDelete!,
                  danger: true,
                );
                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [edit, const SizedBox(height: 8), delete],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 3, child: edit),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: delete),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

final class _LookTrait extends StatelessWidget {
  const _LookTrait({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return Container(
      constraints: const BoxConstraints(minHeight: 32, minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: fidelity.controlSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fidelity.chromeLine),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.chromeKissText.body.copyWith(
          color: fidelity.mutedInk,
          fontSize: 11,
          height: 18 / 11,
        ),
      ),
    );
  }
}

final class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.onPressed,
    this.danger = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    final colors = context.chromeKiss;
    return Semantics(
      button: true,
      label: label,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          foregroundColor: danger ? colors.danger : fidelity.mutedInk,
          side: BorderSide(color: danger ? colors.danger : fidelity.chromeLine),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

List<String> _traitsFor(Scene scene) {
  final labels = <String>[];
  for (final tag in scene.tags) {
    final label = switch (tag) {
      'eyes' => 'Выразительный',
      'animated' => 'Живой',
      'static' => 'Статичный',
      'face' => 'Игривый',
      'photo' => 'Личный',
      'user' => 'Мой образ',
      _ => null,
    };
    if (label != null && !labels.contains(label)) labels.add(label);
  }
  if (labels.isEmpty) labels.add('Глянцевый');
  return labels.take(3).toList(growable: false);
}
