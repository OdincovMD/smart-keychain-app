import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
import '../../../domain/content/scene.dart';
import '../../../l10n/app_localizations.dart';
import 'scene_renderer.dart';

final class AllLooksSheet extends StatelessWidget {
  const AllLooksSheet({
    required this.scenes,
    required this.selectedSceneId,
    required this.activeSceneId,
    required this.enabled,
    required this.onSceneSelected,
    super.key,
  });

  final List<Scene> scenes;
  final String selectedSceneId;
  final String activeSceneId;
  final bool enabled;
  final ValueChanged<String> onSceneSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.allLooksTitle,
              style: context.chromeKissText.title.copyWith(
                fontFamily: 'NunitoSans',
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sceneLibrarySubtitle,
              style: context.chromeKissText.body.copyWith(
                color: context.chromeKiss.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: scenes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final scene = scenes[index];
                  return _AllLookRow(
                    key: Key('all_scene_${scene.id}'),
                    scene: scene,
                    selected: scene.id == selectedSceneId,
                    active: scene.id == activeSceneId,
                    enabled: enabled,
                    onPressed: () => onSceneSelected(scene.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AllLookRow extends StatelessWidget {
  const _AllLookRow({
    required this.scene,
    required this.selected,
    required this.active,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final Scene scene;
  final bool selected;
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: active ? '${scene.name}, ${l10n.activeScene}' : scene.name,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.lens,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? colors.materialChrome
                            : colors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: SceneRenderer(scene: scene, animate: false),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      scene.name,
                      style: context.chromeKissText.body.copyWith(
                        color: colors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (active)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.accentOptical,
                    )
                  else if (selected)
                    Icon(
                      Icons.radio_button_checked_rounded,
                      color: colors.materialChrome,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
