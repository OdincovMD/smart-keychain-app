import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../domain/content/scene.dart';
import '../../../l10n/app_localizations.dart';
import 'scene_renderer.dart';

final class SceneCard extends StatelessWidget {
  const SceneCard({
    required this.scene,
    required this.isSelected,
    required this.isActive,
    required this.enabled,
    required this.onSelected,
    super.key,
  });

  final Scene scene;
  final bool isSelected;
  final bool isActive;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderColor = isSelected ? AppColors.mint : Colors.transparent;

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        key: Key('scene_${scene.id}'),
        onTap: enabled ? onSelected : null,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          width: 172,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SceneRenderer(scene: scene, animate: false),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.activeScene,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.mint,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                scene.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 17),
              ),
              if (scene.description case final description?) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
