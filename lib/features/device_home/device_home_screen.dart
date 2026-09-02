import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_colors.dart';
import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../application/user_image_workflow.dart';
import '../../domain/content/scene.dart';
import '../../domain/device/device_connection_status.dart';
import '../../domain/device/device_snapshot.dart';
import '../../domain/eyes/eye_emotion.dart';
import '../../domain/image/crop_spec.dart';
import '../../domain/image/user_image_failure.dart';
import '../../l10n/app_localizations.dart';
import '../device_discovery/device_discovery_screen.dart';
import '../image_editor/image_editor_screen.dart';
import '../image_import/user_image_controller.dart';
import '../shared/playful_background.dart';
import 'eye_preview_controller.dart';
import 'widgets/brightness_control.dart';
import 'widgets/keychain_preview.dart';
import 'widgets/scene_card.dart';

final class DeviceHomeScreen extends ConsumerStatefulWidget {
  const DeviceHomeScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<DeviceHomeScreen> createState() => _DeviceHomeScreenState();
}

final class _DeviceHomeScreenState extends ConsumerState<DeviceHomeScreen> {
  String? _selectedSceneId;

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
            setState(() => _selectedSceneId = sceneId);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.imageSaved)));
          }
          ref.read(userImageControllerProvider.notifier).acknowledge();
        case UserImageFailed(:final failure):
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_imageFailureLabel(l10n, failure))),
            );
          }
          ref.read(userImageControllerProvider.notifier).acknowledge();
        case UserImageIdle() || UserImagePicking() || UserImageSaving():
          break;
      }
    });

    return Scaffold(
      body: PlayfulBackground(
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
    final cropSpec = await Navigator.of(context).push<CropSpec>(
      MaterialPageRoute(builder: (context) => ImageEditorScreen(draft: draft)),
    );
    if (!mounted) return;
    if (cropSpec == null) {
      ref.read(userImageControllerProvider.notifier).cancel();
      return;
    }
    final profile = ref.read(deviceSnapshotProvider).value?.displayProfile;
    if (profile == null) {
      ref.read(userImageControllerProvider.notifier).cancel();
      return;
    }
    ref.read(userImageControllerProvider.notifier).save(cropSpec, profile);
  }

  void _retrySceneLibrary() {
    ref.invalidate(sceneLibraryProvider);
    ref.invalidate(sceneByIdProvider);
  }

  Future<void> _showSimulatorSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
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
  final VoidCallback onDisconnect;
  final VoidCallback onOpenSimulatorSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedIsActive = selectedSceneId == snapshot.activeSceneId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.deviceHomeEyebrow,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.mint,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.demoKeychain,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  if (kDebugMode)
                    Semantics(
                      label: l10n.openSimulatorSettings,
                      button: true,
                      child: IconButton.filledTonal(
                        key: const Key('simulator_settings_button'),
                        onPressed: onOpenSimulatorSettings,
                        tooltip: l10n.openSimulatorSettings,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    key: const Key('disconnect_button'),
                    onPressed: isBusy ? null : onDisconnect,
                    tooltip: l10n.disconnect,
                    icon: const Icon(Icons.link_off_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _StatusPill(snapshot: snapshot),
                  const SizedBox(width: 10),
                  _BatteryPill(value: snapshot.batteryPercent),
                ],
              ),
              const SizedBox(height: 18),
              KeychainPreview(
                scene: activeScene,
                displayProfile: snapshot.displayProfile,
                snapshot: snapshot,
              ),
              const SizedBox(height: 8),
              BrightnessControl(
                value: snapshot.brightness,
                enabled: !isBusy,
                onChangeEnd: onBrightnessChanged,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sceneLibrary,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    key: const Key('add_user_image_button'),
                    onPressed: isBusy ? null : onAddImage,
                    tooltip: l10n.addImage,
                    icon: isAddingImage
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.sceneLibrarySubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 282,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: scenes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    return SceneCard(
                      scene: scene,
                      isSelected: scene.id == selectedSceneId,
                      isActive: scene.id == snapshot.activeSceneId,
                      enabled: !isBusy,
                      onSelected: () => onSceneSelected(scene.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('install_scene_button'),
                onPressed: isBusy || selectedIsActive ? null : onInstallScene,
                icon: isBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Icon(
                        selectedIsActive
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                      ),
                label: Text(
                  isBusy
                      ? l10n.installing
                      : selectedIsActive
                      ? l10n.installed
                      : l10n.installScene,
                ),
              ),
            ],
          ),
        ),
      ),
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

final class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.snapshot});

  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (snapshot.connectionStatus) {
      DeviceConnectionStatus.ready => l10n.statusReady,
      DeviceConnectionStatus.connecting => l10n.statusConnecting,
      DeviceConnectionStatus.discovering => l10n.statusDiscovering,
      DeviceConnectionStatus.disconnecting => l10n.statusDisconnecting,
      _ => l10n.statusDisconnected,
    };
    final online = snapshot.connectionStatus == DeviceConnectionStatus.ready;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: online ? AppColors.mint : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: online ? AppColors.mint : AppColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

final class _BatteryPill extends StatelessWidget {
  const _BatteryPill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.battery_5_bar_rounded,
            size: 17,
            color: AppColors.amber,
          ),
          const SizedBox(width: 5),
          Text(
            l10n.percentValue(value),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.cream, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

final class _SimulatorSettingsSheet extends ConsumerWidget {
  const _SimulatorSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const Key('eye_blink_button'),
                  onPressed: () => ref
                      .read(eyePreviewControllerProvider.notifier)
                      .requestBlink(),
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(l10n.blinkNow),
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

String _emotionLabel(AppLocalizations l10n, EyeEmotion emotion) {
  return switch (emotion) {
    EyeEmotion.neutral => l10n.eyeEmotionNeutral,
    EyeEmotion.happy => l10n.eyeEmotionHappy,
    EyeEmotion.sleepy => l10n.eyeEmotionSleepy,
    EyeEmotion.surprised => l10n.eyeEmotionSurprised,
  };
}

String _imageFailureLabel(AppLocalizations l10n, UserImageFailure failure) {
  return switch (failure) {
    UnsupportedImageFailure() => l10n.imageUnsupported,
    ImageReadFailure() => l10n.imageReadFailed,
    ImageProcessingFailure() => l10n.imageProcessingFailed,
    ImageStorageFailure() => l10n.imageStorageFailed,
    ImagePersistenceFailure() => l10n.imagePersistenceFailed,
    ImageDeviceFallbackFailure() => l10n.imageDeviceFallbackFailed,
  };
}
