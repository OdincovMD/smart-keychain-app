import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../application/user_image_workflow.dart';
import '../../domain/content/scene.dart';
import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_snapshot.dart';
import '../../domain/eyes/eye_emotion.dart';
import '../../domain/settings/app_appearance.dart';
import '../appearance/appearance_controller.dart';
import '../../l10n/app_localizations.dart';
import '../device_discovery/device_discovery_screen.dart';
import '../image_editor/image_editor_screen.dart';
import '../image_import/user_image_controller.dart';
import '../shared/image_failure_label.dart';
import '../user_content/user_content_screen.dart';
import 'eye_preview_controller.dart';
import 'widgets/brightness_control.dart';
import 'widgets/character_study_screen.dart';
import 'widgets/companion_stage.dart';
import 'widgets/jewel_button.dart';
import 'widgets/status_glyph.dart';
import 'widgets/wardrobe_rail.dart';

final class DeviceHomeScreen extends ConsumerStatefulWidget {
  const DeviceHomeScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<DeviceHomeScreen> createState() => _DeviceHomeScreenState();
}

final class _DeviceHomeScreenState extends ConsumerState<DeviceHomeScreen> {
  String? _selectedSceneId;
  String? _newLookSceneId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(deviceSnapshotProvider);
    final command = ref.watch(deviceControllerProvider);
    final scenes = ref.watch(sceneLibraryProvider);
    final imageFlow = ref.watch(userImageControllerProvider);
    final imageBusy =
        imageFlow is UserImagePicking || imageFlow is UserImageSaving;

    ref.listen(connectionStateProvider, (previous, next) {
      if (next.value == DeviceConnectionStatus.disconnected && mounted) {
        context.go(DeviceDiscoveryScreen.routePath);
      }
    });
    ref.listen(deviceControllerProvider, (previous, next) {
      if (next.hasError && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.connectionError)));
      }
    });
    ref.listen(userImageControllerProvider, (previous, next) {
      switch (next) {
        case UserImageEditing(:final draft) when previous is! UserImageEditing:
          unawaited(_openImageEditor(draft));
        case UserImageEditing():
          break;
        case UserImageCompleted(:final sceneId):
          if (mounted) {
            setState(() {
              _selectedSceneId = sceneId;
              _newLookSceneId = sceneId;
            });
          }
          ref.read(userImageControllerProvider.notifier).acknowledge();
        case UserImageFailed(:final failure):
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(imageFailureLabel(l10n, failure))),
            );
          }
          ref.read(userImageControllerProvider.notifier).acknowledge();
        case UserImageIdle() || UserImagePicking() || UserImageSaving():
          break;
      }
    });

    return Scaffold(
      body: ColoredBox(
        color: context.chromeKiss.canvas,
        child: SafeArea(
          child: snapshot.when(
            data: (value) => scenes.when(
              data: (items) => ref
                  .watch(sceneByIdProvider(value.activeSceneId))
                  .when(
                    data: (activeScene) => activeScene == null
                        ? _SceneLibraryError(onRetry: _retrySceneLibrary)
                        : _DeviceHomeContent(
                            snapshot: value,
                            scenes: items,
                            activeScene: activeScene,
                            selectedSceneId:
                                _selectedSceneId ?? value.activeSceneId,
                            isBusy: command.isLoading || imageBusy,
                            isAddingImage: imageBusy,
                            onSceneSelected: (sceneId) {
                              setState(() => _selectedSceneId = sceneId);
                            },
                            onInstallScene: () => ref
                                .read(deviceControllerProvider.notifier)
                                .setScene(
                                  _selectedSceneId ?? value.activeSceneId,
                                ),
                            onBrightnessChanged: (brightness) => ref
                                .read(deviceControllerProvider.notifier)
                                .setBrightness(brightness),
                            onAddImage: () => ref
                                .read(userImageControllerProvider.notifier)
                                .startImport(),
                            onOpenMyContent: () => unawaited(_openMyContent()),
                            onDisconnect: () => ref
                                .read(deviceControllerProvider.notifier)
                                .disconnect(),
                            onOpenSimulatorSettings: () =>
                                _showSimulatorSettings(context),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) =>
                        _SceneLibraryError(onRetry: _retrySceneLibrary),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  _SceneLibraryError(onRetry: _retrySceneLibrary),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: FilledButton(
                onPressed: () => context.go(DeviceDiscoveryScreen.routePath),
                child: Text(l10n.retry),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openImageEditor(PendingUserImage draft) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          assetId: draft.id,
          originalBytes: draft.originalBytes,
          onSave: (cropSpec) async {
            final profile = ref
                .read(deviceSnapshotProvider)
                .value
                ?.displayProfile;
            if (profile == null) return false;
            return ref
                .read(userImageControllerProvider.notifier)
                .save(cropSpec, profile);
          },
        ),
      ),
    );
    if (!mounted) return;
    if (saved == null) {
      ref.read(userImageControllerProvider.notifier).cancel();
      return;
    }
    if (!saved) return;
    final sceneId = _newLookSceneId;
    if (sceneId == null) return;
    _newLookSceneId = null;
    await _openMyContent(highlightedSceneId: sceneId);
  }

  Future<void> _openMyContent({String? highlightedSceneId}) async {
    final result = await Navigator.of(context).push<UserContentScreenResult>(
      MaterialPageRoute(
        builder: (context) =>
            UserContentScreen(highlightedSceneId: highlightedSceneId),
      ),
    );
    if (!mounted || result != UserContentScreenResult.addImage) return;
    ref.read(userImageControllerProvider.notifier).startImport();
  }

  void _retrySceneLibrary() {
    ref.invalidate(sceneLibraryProvider);
    ref.invalidate(sceneByIdProvider);
  }

  Future<void> _showSimulatorSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.chromeKiss.surfaceSecondary,
      showDragHandle: true,
      builder: (context) => const _SimulatorSettingsSheet(),
    );
  }
}

final class _DeviceHomeContent extends StatelessWidget {
  const _DeviceHomeContent({
    required this.snapshot,
    required this.scenes,
    required this.activeScene,
    required this.selectedSceneId,
    required this.isBusy,
    required this.isAddingImage,
    required this.onSceneSelected,
    required this.onInstallScene,
    required this.onBrightnessChanged,
    required this.onAddImage,
    required this.onOpenMyContent,
    required this.onDisconnect,
    required this.onOpenSimulatorSettings,
  });

  final DeviceSnapshot snapshot;
  final List<Scene> scenes;
  final Scene activeScene;
  final String selectedSceneId;
  final bool isBusy;
  final bool isAddingImage;
  final ValueChanged<String> onSceneSelected;
  final VoidCallback onInstallScene;
  final ValueChanged<double> onBrightnessChanged;
  final VoidCallback onAddImage;
  final VoidCallback onOpenMyContent;
  final VoidCallback onDisconnect;
  final VoidCallback onOpenSimulatorSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final selectedIsActive = selectedSceneId == snapshot.activeSceneId;
    final connectionLabel = switch (snapshot.connectionStatus) {
      DeviceConnectionStatus.ready => l10n.statusReady,
      DeviceConnectionStatus.connecting => l10n.statusConnecting,
      DeviceConnectionStatus.discovering => l10n.statusDiscovering,
      DeviceConnectionStatus.disconnecting => l10n.statusDisconnecting,
      _ => l10n.statusDisconnected,
    };
    final connected = snapshot.connectionStatus == DeviceConnectionStatus.ready;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final stageDiameter = math.min(
          constraints.maxWidth - 40,
          math.min(326.0, math.max(248.0, viewportHeight * 0.365)),
        );
        final largeText = MediaQuery.textScalerOf(context).scale(12) > 17;
        final stackHeader = largeText || constraints.maxWidth < 350;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CompanionHeader(
                    activeSceneName: activeScene.name,
                    connectionLabel: connectionLabel,
                    connected: connected,
                    batteryPercent: snapshot.batteryPercent,
                    stackStatus: stackHeader,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Transform.translate(
                      offset: const Offset(-6, 0),
                      child: CompanionStage(
                        scene: activeScene,
                        displayProfile: snapshot.displayProfile,
                        snapshot: snapshot,
                        diameter: stageDiameter,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    container: true,
                    child: Column(
                      key: const Key('companion_presence'),
                      children: [
                        Text(
                          l10n.moodNeutral,
                          textAlign: TextAlign.center,
                          style: context.chromeKissText.title.copyWith(
                            color: colors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.55,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.presenceNeutral,
                          textAlign: TextAlign.center,
                          style: context.chromeKissText.body.copyWith(
                            color: colors.textSecondary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  JewelButton(
                    key: const Key('install_scene_button'),
                    label: isBusy ? l10n.tryingOn : l10n.changeLook,
                    busy: isBusy,
                    onPressed: isBusy
                        ? null
                        : selectedIsActive
                        ? onOpenMyContent
                        : onInstallScene,
                  ),
                  const SizedBox(height: 30),
                  WardrobeRail(
                    scenes: scenes,
                    selectedSceneId: selectedSceneId,
                    activeSceneId: snapshot.activeSceneId,
                    enabled: !isBusy,
                    isAddingImage: isAddingImage,
                    onSceneSelected: onSceneSelected,
                    onOpenAll: onOpenMyContent,
                    onAddImage: onAddImage,
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        key: const Key('brightness_settings_button'),
                        onPressed: () => _showBrightness(context),
                        icon: const Icon(Icons.light_mode_outlined, size: 19),
                        label: Text(l10n.brightness),
                      ),
                      TextButton.icon(
                        key: const Key('open_my_content_button'),
                        onPressed: isBusy ? null : onOpenMyContent,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 19,
                        ),
                        label: Text(l10n.myContent),
                      ),
                      IconButton(
                        key: const Key('disconnect_button'),
                        onPressed: isBusy ? null : onDisconnect,
                        tooltip: l10n.disconnect,
                        icon: const Icon(Icons.link_off_rounded, size: 20),
                      ),
                      if (kDebugMode)
                        IconButton(
                          key: const Key('simulator_settings_button'),
                          onPressed: onOpenSimulatorSettings,
                          tooltip: l10n.openSimulatorSettings,
                          icon: const Icon(Icons.tune_rounded, size: 20),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBrightness(BuildContext context) async {
    final colors = context.chromeKiss;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceSecondary,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: colors.divider.withValues(alpha: 0.82)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.materialChrome.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const SizedBox(width: 38, height: 3),
                ),
              ),
              const SizedBox(height: 20),
              BrightnessControl(
                value: snapshot.brightness,
                enabled: !isBusy,
                onChangeEnd: onBrightnessChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CompanionHeader extends StatelessWidget {
  const _CompanionHeader({
    required this.activeSceneName,
    required this.connectionLabel,
    required this.connected,
    required this.batteryPercent,
    required this.stackStatus,
  });

  final String activeSceneName;
  final String connectionLabel;
  final bool connected;
  final int batteryPercent;
  final bool stackStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.deviceHomeEyebrow,
          style: context.chromeKissText.status.copyWith(
            color: colors.textSecondary,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          activeSceneName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.chromeKissText.title.copyWith(
            fontSize: 18,
            letterSpacing: -0.35,
          ),
        ),
      ],
    );
    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusGlyph(
          key: const Key('connection_status_glyph'),
          value: connectionLabel,
          semanticLabel: connectionLabel,
          tone: connected ? StatusGlyphTone.connected : StatusGlyphTone.neutral,
        ),
        const SizedBox(width: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.divider.withValues(alpha: 0.72),
          ),
          child: const SizedBox(width: 1, height: 14),
        ),
        const SizedBox(width: 4),
        StatusGlyph(
          key: const Key('battery_status_glyph'),
          value: l10n.percentValue(batteryPercent),
          semanticLabel: l10n.batteryPercent(batteryPercent),
          tone: StatusGlyphTone.battery,
        ),
      ],
    );

    if (stackStatus) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [identity, const SizedBox(height: 8), status],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: identity),
        const SizedBox(width: 12),
        Flexible(child: status),
      ],
    );
  }
}

final class _SceneLibraryError extends StatelessWidget {
  const _SceneLibraryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context).retry),
      ),
    );
  }
}

final class _SimulatorSettingsSheet extends ConsumerWidget {
  const _SimulatorSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appearance = ref.watch(appAppearanceProvider);
    final current =
        ref.watch(simulatorLatencyProvider).value ??
        const Duration(milliseconds: 300);
    final latencyPresets = ref.watch(simulatorControlsProvider).latencyPresets;
    final activeSceneId = ref
        .watch(deviceSnapshotProvider)
        .value
        ?.activeSceneId;
    final activeScene = activeSceneId == null
        ? null
        : ref.watch(sceneByIdProvider(activeSceneId)).value;
    final supportsEyes = activeScene?.content is ProceduralEyesContent;
    final eyeState = supportsEyes
        ? ref.watch(eyePreviewControllerProvider)
        : null;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.simulatorSettings,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.simulatorSettingsHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Text(
                l10n.appearance,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.appearanceHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in AppAppearance.values)
                    ChoiceChip(
                      key: Key('appearance_${value.name}'),
                      label: Text(_appearanceLabel(l10n, value)),
                      selected: value == appearance,
                      onSelected: (_) => ref
                          .read(appAppearanceProvider.notifier)
                          .setAppearance(value),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const Divider(),
              const SizedBox(height: 18),
              Text(l10n.latency, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final latency in latencyPresets)
                    ChoiceChip(
                      key: Key('latency_${latency.inMilliseconds}'),
                      label: Text(l10n.latencyValue(latency.inMilliseconds)),
                      selected: latency == current,
                      onSelected: (_) => ref
                          .read(simulatorControlsProvider)
                          .setLatency(latency),
                    ),
                ],
              ),
              if (eyeState != null) ...[
                const SizedBox(height: 26),
                const Divider(),
                const SizedBox(height: 18),
                Text(
                  l10n.eyeEngine,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.eyeEngineHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final emotion in EyeEmotion.values)
                      ChoiceChip(
                        key: Key('eye_emotion_${emotion.name}'),
                        label: Text(_emotionLabel(l10n, emotion)),
                        selected: eyeState.emotion == emotion,
                        onSelected: (_) => ref
                            .read(eyePreviewControllerProvider.notifier)
                            .setEmotion(emotion),
                      ),
                  ],
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const Key('open_character_study_button'),
                    onPressed: () {
                      final navigator = Navigator.of(
                        context,
                        rootNavigator: true,
                      );
                      Navigator.of(context).pop();
                      unawaited(
                        navigator.push<void>(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => const CharacterStudyScreen(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Kiss Cut character study'),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('eye_blink_button'),
                      onPressed: () => ref
                          .read(eyePreviewControllerProvider.notifier)
                          .requestBlink(),
                      icon: const Icon(Icons.visibility_rounded),
                      label: Text(l10n.blinkNow),
                    ),
                    OutlinedButton(
                      key: const Key('eye_double_blink_button'),
                      onPressed: () => ref
                          .read(eyePreviewControllerProvider.notifier)
                          .requestDoubleBlink(),
                      child: const Text('Двойное моргание'),
                    ),
                    OutlinedButton(
                      key: const Key('eye_look_left_button'),
                      onPressed: () => ref
                          .read(eyePreviewControllerProvider.notifier)
                          .requestLookLeft(),
                      child: const Text('Взгляд влево'),
                    ),
                    OutlinedButton(
                      key: const Key('eye_look_right_button'),
                      onPressed: () => ref
                          .read(eyePreviewControllerProvider.notifier)
                          .requestLookRight(),
                      child: const Text('Взгляд вправо'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('eye_special_action_button'),
                      onPressed: () => ref
                          .read(eyePreviewControllerProvider.notifier)
                          .requestSpecialAction(),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Поймать огонёк'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Источник случайности',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final seed in <int?>[null, 7, 42])
                      ChoiceChip(
                        key: Key('eye_seed_${seed ?? 'natural'}'),
                        label: Text(seed == null ? 'Natural' : 'Seed $seed'),
                        selected: eyeState.randomSeed == seed,
                        onSelected: (_) => ref
                            .read(eyePreviewControllerProvider.notifier)
                            .setRandomSeed(seed),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
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

String _emotionLabel(AppLocalizations l10n, EyeEmotion emotion) {
  return switch (emotion) {
    EyeEmotion.neutral => l10n.eyeEmotionNeutral,
    EyeEmotion.happy => l10n.eyeEmotionHappy,
    EyeEmotion.sleepy => l10n.eyeEmotionSleepy,
    EyeEmotion.curious => 'Любопытный',
    EyeEmotion.annoyed => 'Недовольный',
    EyeEmotion.surprised => l10n.eyeEmotionSurprised,
  };
}
