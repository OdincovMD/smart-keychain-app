import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/chrome_kiss_theme.dart';
import '../../../core/result.dart';
import '../../../domain/eyes/eye_emotion.dart';
import '../../../domain/eyes/eye_motion_definition.dart';
import '../../../domain/eyes/eye_motion_library.dart';
import '../../../domain/eyes/eye_motion_production.dart';
import '../eye_preview_controller.dart';
import 'eye_motion_ticker.dart';
import 'kiss_cut_eye_renderer.dart';
import 'procedural_eyes_view.dart';

enum CharacterStudySize { full, thumbnail }

enum CharacterStudyMotionSource { builtIn, productionAsset }

final class CharacterStudyScreen extends ConsumerStatefulWidget {
  const CharacterStudyScreen({super.key});

  @override
  ConsumerState<CharacterStudyScreen> createState() =>
      _CharacterStudyScreenState();
}

final class _CharacterStudyScreenState
    extends ConsumerState<CharacterStudyScreen> {
  EyeRendererVariant _renderer = EyeRendererVariant.kissCutV21;
  KissCutVisualMood _mood = KissCutVisualMood.neutral;
  KissCutColourway _colourway = KissCutColourway.orchidLilac;
  CharacterStudySize _size = CharacterStudySize.full;
  CharacterStudyMotionSource _motionSource = CharacterStudyMotionSource.builtIn;
  EyeMotionDefinition _definition = chromeKissEyeMotionDefinition;
  EyeMotionTicker? _runtime;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final eyeState = ref.watch(eyePreviewControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kiss Cut Character Study')),
      body: ColoredBox(
        color: colors.canvas,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'PROPOSED · NOT PRODUCTION DEFAULT',
                      style: context.chromeKissText.status.copyWith(
                        color: colors.materialChampagne,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Legacy / Kiss Cut V2 / V2.1',
                      style: context.chromeKissText.title.copyWith(
                        fontFamily: 'NunitoSans',
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Isolated renderer study on the same behaviour engine.',
                      style: context.chromeKissText.body.copyWith(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _CharacterPreview(
                      renderer: _renderer,
                      mood: _mood,
                      colourway: _colourway,
                      size: _size,
                      definition: _definition,
                      onRuntimeReady: _captureRuntime,
                    ),
                    const SizedBox(height: 10),
                    _MotionReadout(runtime: _runtime),
                    const SizedBox(height: 24),
                    _StudySection(
                      label: 'Motion source',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final source
                              in CharacterStudyMotionSource.values)
                            ChoiceChip(
                              key: Key('study_source_${source.name}'),
                              label: Text(_motionSourceLabel(source)),
                              selected: _motionSource == source,
                              onSelected: (_) => _selectMotionSource(source),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StudySection(
                      label: 'Renderer',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final renderer in EyeRendererVariant.values)
                            ChoiceChip(
                              key: Key('study_renderer_${renderer.name}'),
                              label: Text(_rendererLabel(renderer)),
                              selected: _renderer == renderer,
                              onSelected: (_) {
                                setState(() => _renderer = renderer);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StudySection(
                      label: 'Motion clip',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final clip in _definition.clips.keys)
                            ChoiceChip(
                              key: Key('study_clip_$clip'),
                              label: Text(clip),
                              selected: eyeState.clipName == clip,
                              onSelected: (_) => ref
                                  .read(eyePreviewControllerProvider.notifier)
                                  .setClip(clip),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StudySection(
                      label: 'Playback',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            key: const Key('study_play'),
                            onPressed: ref
                                .read(eyePreviewControllerProvider.notifier)
                                .play,
                            child: const Text('Play'),
                          ),
                          OutlinedButton(
                            key: const Key('study_pause'),
                            onPressed: ref
                                .read(eyePreviewControllerProvider.notifier)
                                .pause,
                            child: const Text('Pause'),
                          ),
                          OutlinedButton(
                            key: const Key('study_restart'),
                            onPressed: ref
                                .read(eyePreviewControllerProvider.notifier)
                                .restart,
                            child: const Text('Restart'),
                          ),
                          FilterChip(
                            key: const Key('study_slow_motion'),
                            label: const Text('0.5×'),
                            selected: eyeState.playbackSpeed == 0.5,
                            onSelected: (selected) => ref
                                .read(eyePreviewControllerProvider.notifier)
                                .setPlaybackSpeed(selected ? 0.5 : 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StudySection(
                      label: 'Definition import',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            key: const Key('study_import_fixture'),
                            onPressed: _importOwnedFixture,
                            child: const Text('Import fixture'),
                          ),
                          OutlinedButton(
                            key: const Key('study_import_converted'),
                            onPressed: _importConvertedFixture,
                            child: const Text('Converted definition'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StudySection(
                      label: 'Mood',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final mood in KissCutVisualMood.values)
                            ChoiceChip(
                              key: Key('study_mood_${mood.name}'),
                              label: Text(_moodLabel(mood)),
                              selected: _mood == mood,
                              onSelected: (_) => _selectMood(mood),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StudySection(
                      label: 'Scale',
                      child: SegmentedButton<CharacterStudySize>(
                        segments: const [
                          ButtonSegment(
                            value: CharacterStudySize.full,
                            label: Text('Full'),
                          ),
                          ButtonSegment(
                            value: CharacterStudySize.thumbnail,
                            label: Text('64 px'),
                          ),
                        ],
                        selected: {_size},
                        onSelectionChanged: (value) {
                          setState(() => _size = value.single);
                        },
                      ),
                    ),
                    if (_renderer != EyeRendererVariant.legacy) ...[
                      const SizedBox(height: 18),
                      _StudySection(
                        label: 'Colour study',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final colourway in KissCutColourway.values)
                              ChoiceChip(
                                key: Key('study_colourway_${colourway.name}'),
                                label: Text(_colourwayLabel(colourway)),
                                selected: _colourway == colourway,
                                onSelected: (_) {
                                  setState(() => _colourway = colourway);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _StudySection(
                      label: 'Motion checks',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            key: const Key('study_blink'),
                            onPressed: () => ref
                                .read(eyePreviewControllerProvider.notifier)
                                .requestBlink(),
                            child: const Text('Blink'),
                          ),
                          OutlinedButton(
                            key: const Key('study_double_blink'),
                            onPressed: () => ref
                                .read(eyePreviewControllerProvider.notifier)
                                .requestDoubleBlink(),
                            child: const Text('Double blink'),
                          ),
                          OutlinedButton(
                            key: const Key('study_look_left'),
                            onPressed: () => ref
                                .read(eyePreviewControllerProvider.notifier)
                                .requestLookLeft(),
                            child: const Text('Look left'),
                          ),
                          OutlinedButton(
                            key: const Key('study_look_right'),
                            onPressed: () => ref
                                .read(eyePreviewControllerProvider.notifier)
                                .requestLookRight(),
                            child: const Text('Look right'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StudySection(
                      label: 'Random source',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final seed in <int?>[null, 7, 42])
                            ChoiceChip(
                              key: Key('study_seed_${seed ?? 'natural'}'),
                              label: Text(
                                seed == null ? 'Natural' : 'Seed $seed',
                              ),
                              selected: eyeState.randomSeed == seed,
                              onSelected: (_) => ref
                                  .read(eyePreviewControllerProvider.notifier)
                                  .setRandomSeed(seed),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectMood(KissCutVisualMood mood) {
    ref
        .read(eyePreviewControllerProvider.notifier)
        .setEmotion(_runtimeMoodFor(mood));
    setState(() => _mood = mood);
  }

  void _captureRuntime(EyeMotionTicker runtime) {
    if (identical(_runtime, runtime)) return;
    setState(() => _runtime = runtime);
  }

  void _selectMotionSource(CharacterStudyMotionSource source) {
    if (_motionSource == source) return;
    final definition = switch (source) {
      CharacterStudyMotionSource.builtIn => chromeKissEyeMotionDefinition,
      CharacterStudyMotionSource.productionAsset => ref.read(
        productionEyeMotionDefinitionProvider,
      ),
    };
    final clip = resolveInitialEyeMotionClip(definition);
    ref.read(eyePreviewControllerProvider.notifier).setClip(clip);
    setState(() {
      _motionSource = source;
      _definition = definition;
      _runtime = null;
    });
  }

  void _importOwnedFixture() {
    final decoded = decodeEyeMotionDefinition(
      chromeKissEyeMotionDefinition.encode(),
    );
    if (decoded case Ok(:final value)) {
      ref
          .read(eyePreviewControllerProvider.notifier)
          .setClip(resolveInitialEyeMotionClip(value));
      setState(() {
        _runtime = null;
        _motionSource = CharacterStudyMotionSource.builtIn;
        _definition = value;
      });
    }
  }

  void _importConvertedFixture() {
    ref
        .read(eyePreviewControllerProvider.notifier)
        .setClip(ChromeKissEyeClips.neutralIdle);
    setState(() {
      _runtime = null;
      _motionSource = CharacterStudyMotionSource.builtIn;
      _definition = EyeMotionDefinition(
        poses: chromeKissEyeMotionDefinition.poses,
        clips: chromeKissEyeMotionDefinition.clips,
        metadata: const {
          'sourceFormat': 'avatar-definition-v1',
          'fixture': 'clean-room',
        },
      );
    });
  }
}

final class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({
    required this.renderer,
    required this.mood,
    required this.colourway,
    required this.size,
    required this.definition,
    required this.onRuntimeReady,
  });

  final EyeRendererVariant renderer;
  final KissCutVisualMood mood;
  final KissCutColourway colourway;
  final CharacterStudySize size;
  final EyeMotionDefinition definition;
  final ValueChanged<EyeMotionTicker> onRuntimeReady;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = size == CharacterStudySize.thumbnail
            ? 64.0
            : constraints.maxWidth.clamp(240.0, 300.0).toDouble();
        return SizedBox(
          height: size == CharacterStudySize.thumbnail ? 144 : diameter,
          child: Center(
            child: ClipOval(
              child: SizedBox.square(
                key: const Key('character_study_preview'),
                dimension: diameter,
                child: ProceduralEyesView(
                  initialEmotion: _runtimeMoodFor(mood),
                  rendererVariant: renderer,
                  kissCutVisualMoodOverride:
                      renderer == EyeRendererVariant.legacy ? null : mood,
                  kissCutColourway: colourway,
                  motionDefinition: definition,
                  onRuntimeReady: onRuntimeReady,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _MotionReadout extends StatelessWidget {
  const _MotionReadout({required this.runtime});

  final EyeMotionTicker? runtime;

  @override
  Widget build(BuildContext context) {
    final source = runtime;
    if (source == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: source,
      builder: (context, child) {
        final state = source.state;
        return Text(
          'phase ${source.phase.name} · '
          'gaze ${state.gazeX.toStringAsFixed(2)}, '
          '${state.gazeY.toStringAsFixed(2)} · '
          'lids ${state.leftEyelidOpen.toStringAsFixed(2)}/'
          '${state.rightEyelidOpen.toStringAsFixed(2)} · '
          'pupil ${state.pupilScale.toStringAsFixed(2)}',
          key: const Key('study_motion_readout'),
          textAlign: TextAlign.center,
          style: context.chromeKissText.status,
        );
      },
    );
  }
}

final class _StudySection extends StatelessWidget {
  const _StudySection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.chromeKissText.label),
        const SizedBox(height: 9),
        child,
      ],
    );
  }
}

EyeEmotion _runtimeMoodFor(KissCutVisualMood mood) {
  return switch (mood) {
    KissCutVisualMood.neutral || KissCutVisualMood.flirty => EyeEmotion.neutral,
    KissCutVisualMood.happy => EyeEmotion.happy,
    KissCutVisualMood.sleepy => EyeEmotion.sleepy,
    KissCutVisualMood.curious => EyeEmotion.curious,
    KissCutVisualMood.annoyed => EyeEmotion.annoyed,
    KissCutVisualMood.surprised => EyeEmotion.surprised,
  };
}

String _moodLabel(KissCutVisualMood mood) {
  return switch (mood) {
    KissCutVisualMood.neutral => 'Neutral',
    KissCutVisualMood.happy => 'Happy',
    KissCutVisualMood.sleepy => 'Sleepy',
    KissCutVisualMood.curious => 'Curious',
    KissCutVisualMood.annoyed => 'Annoyed',
    KissCutVisualMood.surprised => 'Surprised',
    KissCutVisualMood.flirty => 'Flirty',
  };
}

String _colourwayLabel(KissCutColourway colourway) {
  return switch (colourway) {
    KissCutColourway.orchidLilac => 'Glossy Orchid',
    KissCutColourway.icyCool => 'Mint Glow',
    KissCutColourway.lilacDream => 'Lilac Dream',
    KissCutColourway.pearlChampagne => 'Pearl / Champagne',
  };
}

String _rendererLabel(EyeRendererVariant renderer) {
  return switch (renderer) {
    EyeRendererVariant.legacy => 'Legacy',
    EyeRendererVariant.kissCutV2 => 'Kiss Cut V2',
    EyeRendererVariant.kissCutV21 => 'Kiss Cut V2.1',
    EyeRendererVariant.figmaJewelry => 'Figma Jewelry',
  };
}

String _motionSourceLabel(CharacterStudyMotionSource source) {
  return switch (source) {
    CharacterStudyMotionSource.builtIn => 'Built-in',
    CharacterStudyMotionSource.productionAsset => 'Production asset',
  };
}
