import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

import '../support/neutral_realtime_capture.dart';

final _artifactDirectory = Directory(
  'artifacts/neutral-living-idle-v2/realtime',
);

void main() {
  test('fixed-step plans have exact frame counts and sequential deltas', () {
    for (final spec in _allSpecs) {
      expect(spec.frameCount, spec.framesPerSecond * spec.duration.inSeconds);
      var previous = Duration.zero;
      for (var frame = 0; frame < spec.frameCount; frame++) {
        final time = spec.frameTime(frame);
        expect(time, greaterThanOrEqualTo(previous));
        if (frame > 0) {
          expect(spec.frameDelta(frame), greaterThan(Duration.zero));
          expect(time, previous + spec.frameDelta(frame));
        }
        previous = time;
      }
      final gifDurationCentiseconds = List.generate(
        spec.frameCount,
        spec.gifDelayCentiseconds,
      ).fold<int>(0, (total, delay) => total + delay);
      expect(gifDurationCentiseconds * 10, spec.duration.inMilliseconds);
    }
  });

  test('seed 4 and the 30 FPS delta sequence produce the same state trace', () {
    final first = _deterministicTrace();
    final second = _deterministicTrace();

    expect(first, second);
    expect(fnv1a64(jsonEncode(first)), fnv1a64(jsonEncode(second)));
    expect(first.first['timeMs'], 0);
    expect(first.last['timeMs'], neutralCloseupSpec.duration.inMilliseconds);
  });

  test(
    'fallback GIFs contain the declared frames, dimensions and duration',
    () {
      for (final spec in _allSpecs) {
        final file = File('${_artifactDirectory.path}/${spec.name}.gif');
        expect(file.existsSync(), isTrue, reason: file.path);
        final decoder = image.GifDecoder(file.readAsBytesSync());
        final info = decoder.info;
        expect(info, isNotNull, reason: file.path);
        expect(info!.width, spec.width, reason: file.path);
        expect(info.height, spec.height, reason: file.path);
        expect(info.numFrames, spec.frameCount, reason: file.path);
        final durationMs = info.frames.fold<int>(
          0,
          (total, frame) => total + frame.duration * 10,
        );
        expect(durationMs, spec.duration.inMilliseconds, reason: file.path);
        expect(
          file.lengthSync(),
          inInclusiveRange(10 * 1024, 50 * 1024 * 1024),
        );
      }
    },
  );

  test('trace metadata and digest match the final close-up runtime', () {
    final file = File(
      '${_artifactDirectory.path}/neutral-living-idle-seed-4-trace.json',
    );
    final trace = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final metadata = trace['metadata']! as Map<String, Object?>;
    final samples = (trace['samples']! as List<Object?>)
        .cast<Map<String, Object?>>();

    expect(metadata['seed'], neutralCaptureSeed);
    expect(metadata['speed'], neutralCaptureSpeed);
    expect(metadata['fps'], neutralCloseupSpec.framesPerSecond);
    expect(metadata['durationMs'], neutralCloseupSpec.duration.inMilliseconds);
    expect(metadata['frameCount'], neutralCloseupSpec.frameCount);
    expect(metadata['captureFormat'], 'animated-gif-fallback-no-ffmpeg');
    expect(samples.first['timeMs'], 0);
    expect(
      samples.last['timeMs'],
      closeTo(neutralCloseupSpec.duration.inMilliseconds, 1),
    );
    for (var index = 1; index < samples.length; index++) {
      expect(
        samples[index]['timeMs'],
        greaterThan(samples[index - 1]['timeMs']! as int),
      );
    }
    expect(metadata['stateTraceDigest'], fnv1a64(jsonEncode(samples)));
  });

  test('capture leaves no PNG sequence and is absent from the app bundle', () {
    final trackedPngSequence = _artifactDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.png'));
    expect(trackedPngSequence, isEmpty);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('artifacts/neutral-living-idle-v2')));
    expect(pubspec, isNot(contains('test/support/neutral_realtime_capture')));
    final bundledCaptureReferences = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) =>
              file.readAsStringSync().contains('neutral_realtime_capture'),
        );
    expect(bundledCaptureReferences, isEmpty);
  });
}

List<Map<String, Object?>> _deterministicTrace() {
  final player = EyeMotionPlayer(
    behaviourEngine: EyeBehaviourEngine(Random(neutralCaptureSeed)),
    definition: _productionDefinition(),
    initialClip: 'kiss-idle',
    behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
  )..setSpeed(neutralCaptureSpeed);
  final samples = <Map<String, Object?>>[];
  for (var frame = 0; frame < neutralCloseupSpec.frameCount; frame++) {
    if (frame > 0) {
      player.advance(neutralCloseupSpec.frameDelta(frame));
    }
    if (frame % 3 == 0) samples.add(_sample(player, specTime: frame));
  }
  player.advance(
    neutralCloseupSpec.duration -
        neutralCloseupSpec.frameTime(neutralCloseupSpec.frameCount - 1),
  );
  samples.add({
    ..._sample(player, specTime: neutralCloseupSpec.frameCount),
    'timeMs': neutralCloseupSpec.duration.inMilliseconds,
  });
  return samples;
}

Map<String, Object?> _sample(EyeMotionPlayer player, {required int specTime}) {
  final state = player.state;
  final diagnostics = player.diagnostics;
  return {
    'timeMs': neutralCloseupSpec.frameTime(specTime).inMilliseconds,
    'phase': state.motionPhase.name,
    'gazeX': state.gazeX,
    'gazeY': state.gazeY,
    'leftEyelid': state.leftEyelidOpen,
    'rightEyelid': state.rightEyelidOpen,
    'pupilScale': state.pupilScale,
    'gesture': diagnostics.activeGesture.name,
    'scheduler': diagnostics.schedulerState.name,
  };
}

EyeMotionDefinition _productionDefinition() {
  final decoded = decodeEyeMotionDefinition(
    File(BundledEyeMotionDefinitionLoader.productionAssetPath)
        .readAsStringSync(),
  );
  return switch (decoded) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError(failure.code),
  };
}

const _allSpecs = <NeutralCaptureSpec>[
  neutralCloseupSpec,
  neutralCloseupPreviewSpec,
  neutralHomeSpec,
  neutralBlinkSpec,
  neutralSignatureSpec,
];
