import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/settings/app_appearance.dart';
import '../../l10n/app_localizations.dart';
import '../appearance/appearance_controller.dart';
import '../device_home/widgets/chrome_kiss_eye_reaction_lens.dart';
import '../device_home/widgets/kiss_cut_eye_renderer.dart';

final class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final confirmed = ref.watch(appAppearanceProvider);
    final operation =
        ref.watch(appearancePersistenceProvider).value ??
        const AppearancePersistenceState.idle();
    final failedTarget = operation.status == AppearancePersistenceStatus.failed
        ? operation.target
        : null;

    return SingleChildScrollView(
      key: const Key('appearance_screen_scroll'),
      child: Column(
        key: const Key('appearance_screen'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appearanceMaterialEyebrow,
            style: context.chromeKissText.status.copyWith(
              color: context.chromeKissFidelity.accentInk,
              fontSize: 11,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appearance,
            style: context.chromeKissText.title.copyWith(
              fontSize: 34,
              height: 40 / 34,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.appearanceScreenHint,
            style: context.chromeKissText.body.copyWith(
              color: context.chromeKissFidelity.mutedInk,
              fontSize: 13,
              height: 19 / 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final appearance in AppAppearance.values) ...[
                Expanded(
                  child: AppearanceOption(
                    appearance: appearance,
                    selected: confirmed == appearance,
                    saving:
                        operation.isSaving && operation.target == appearance,
                    onPressed: () => ref
                        .read(appAppearanceProvider.notifier)
                        .setAppearance(appearance),
                  ),
                ),
                if (appearance != AppAppearance.values.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : context.chromeKissMotion.interaction.duration,
            child: failedTarget == null
                ? _AppearanceNote(
                    key: const Key('appearance_instant_note'),
                    icon: Icons.auto_awesome_rounded,
                    message: operation.isSaving
                        ? l10n.appearanceSaving
                        : l10n.appearanceInstantNote,
                  )
                : _AppearanceFailure(
                    key: const Key('appearance_save_failure'),
                    onRetry: () => ref
                        .read(appAppearanceProvider.notifier)
                        .retry(failedTarget),
                  ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('appearance_done_button'),
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

final class AppearanceOption extends StatelessWidget {
  const AppearanceOption({
    required this.appearance,
    required this.selected,
    required this.saving,
    required this.onPressed,
    super.key,
  });

  final AppAppearance appearance;
  final bool selected;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fidelity = context.chromeKissFidelity;
    final label = _appearanceLabel(l10n, appearance);
    final metadata = appearance == AppAppearance.system
        ? l10n.appearanceAutoLabel
        : l10n.appearanceThemeLabel;
    return Semantics(
      button: true,
      selected: selected,
      enabled: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          key: Key('appearance_option_${appearance.name}'),
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? fidelity.lacquer : fidelity.chromeLine,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: saving ? null : onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 132),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      selected ? 8 : 9,
                      selected ? 8 : 9,
                      selected ? 8 : 9,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 85 / 68,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _AppearancePreview(appearance: appearance),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          label,
                          maxLines: 2,
                          style: context.chromeKissText.body.copyWith(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          metadata,
                          style: context.chromeKissText.body.copyWith(
                            color: fidelity.mutedInk,
                            fontSize: 10,
                            height: 14 / 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected || saving)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: fidelity.lacquer,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 24,
                          child: saving
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.chromeKiss.onAccent,
                                  ),
                                )
                              : Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: context.chromeKiss.onAccent,
                                ),
                        ),
                      ),
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

final class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview({required this.appearance});

  final AppAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final previewTheme = switch (appearance) {
      AppAppearance.obsidian => ChromeKissFidelityTheme.obsidian,
      AppAppearance.pearl => ChromeKissFidelityTheme.pearl,
      AppAppearance.system => context.chromeKissFidelity,
    };
    final background = switch (appearance) {
      AppAppearance.obsidian => ChromeKissFidelityTheme.obsidian.satinGradient,
      AppAppearance.pearl => ChromeKissFidelityTheme.pearl.satinGradient,
      AppAppearance.system => LinearGradient(
        colors: [
          ChromeKissFidelityTheme.obsidian.canvas,
          ChromeKissFidelityTheme.obsidian.canvas,
          ChromeKissFidelityTheme.pearl.canvas,
          ChromeKissFidelityTheme.pearl.canvas,
        ],
        stops: [0, 0.49, 0.51, 1],
      ),
    };

    return DecoratedBox(
      key: Key('appearance_preview_${appearance.name}'),
      decoration: BoxDecoration(
        gradient: background,
        border: Border.all(color: previewTheme.chromeLine),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 7,
            child: ChromeKissEyeReactionLens(
              size: ChromeKissEyeReactionLensSize.tiny,
              mood: KissCutVisualMood.neutral,
              animate: false,
              useProductionMotion: false,
            ),
          ),
          Positioned(
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: previewTheme.chromeLine,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(width: 34, height: 3),
            ),
          ),
        ],
      ),
    );
  }
}

final class _AppearanceNote extends StatelessWidget {
  const _AppearanceNote({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final fidelity = context.chromeKissFidelity;
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: fidelity.controlSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fidelity.chromeLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: fidelity.lacquer, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.chromeKissText.body.copyWith(
                color: fidelity.mutedInk,
                fontSize: 12,
                height: 17 / 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _AppearanceFailure extends ConsumerWidget {
  const _AppearanceFailure({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    return Semantics(
      liveRegion: true,
      label: l10n.appearanceSaveFailure,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.fromLTRB(13, 8, 8, 8),
        decoration: BoxDecoration(
          color: colors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.danger.withValues(alpha: 0.62)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.appearanceSaveFailure,
                style: context.chromeKissText.body.copyWith(
                  color: colors.textPrimary,
                  fontSize: 11.5,
                  height: 16 / 11.5,
                ),
              ),
            ),
            TextButton(
              key: const Key('appearance_retry_button'),
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _appearanceLabel(AppLocalizations l10n, AppAppearance appearance) {
  return switch (appearance) {
    AppAppearance.obsidian => l10n.appearanceObsidian,
    AppAppearance.pearl => l10n.appearancePearl,
    AppAppearance.system => l10n.appearanceSystem,
  };
}
