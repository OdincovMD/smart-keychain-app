import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:smart_keychain_app/core/result.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_definition.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_production.dart';
import 'package:smart_keychain_app/features/user_content/look_application_controller.dart';
import 'package:smart_keychain_app/features/user_content/look_eye_reaction_coordinator.dart';
import 'package:smart_keychain_app/infrastructure/eyes/bundled_eye_motion_definition_loader.dart';

import '../support/apply_look_realtime_capture.dart';
import '../support/neutral_realtime_capture.dart';

final _artifactDirectory = Directory('artifacts/apply-look-eye-reaction-v1');

void main() {
  test('fixed-step plans have exact sequential frame counts', () {
    for (final spec in _specs) {
      expect(spec.frameCount, spec.framesPerSecond * spec.duration.inSeconds);
      for (var frame = 1; frame < spec.frameCount; frame++) {
        expect(spec.frameDelta(frame), greaterThan(Duration.zero));
        expect(
          spec.frameTime(frame),
          spec.frameTime(frame - 1) + spec.frameDelta(frame),
        );
      }
      final centiseconds = List.generate(
        spec.frameCount,
        spec.gifDelayCentiseconds,
      ).fold<int>(0, (total, delay) => total + delay);
      expect(centiseconds * 10, spec.duration.inMilliseconds);
    }
  });

  test('same seed and status timeline produce the same compact trace', () {
    final first = _deterministicTrace();
    final second = _deterministicTrace();

    expect(second, first);
    expect(fnv1a64(jsonEncode(second)), fnv1a64(jsonEncode(first)));
    expect(first.first['timeMs'], 0);
    expect(first.last['timeMs'], applyLookSuccessSpec.duration.inMilliseconds);
  });

  test('GIF fallback files match declared frames, dimensions and duration', () {
    for (final spec in _specs) {
      final file = File('${_artifactDirectory.path}/${spec.name}.gif');
      expect(file.existsSync(), isTrue, reason: file.path);
      final info = image.GifDecoder(file.readAsBytesSync()).info;
      expect(info, isNotNull, reason: file.path);
      expect(info!.width, spec.width, reason: file.path);
      expect(info.height, spec.height, reason: file.path);
      expect(info.numFrames, spec.frameCount, reason: file.path);
      expect(
        info.frames.fold<int>(0, (total, frame) => total + frame.duration * 10),
        spec.duration.inMilliseconds,
        reason: file.path,
      );
      expect(file.lengthSync(), inInclusiveRange(10 * 1024, 50 * 1024 * 1024));
    }
  });

  test('trace metadata, endpoints and digest match the capture contract', () {
    final file = File(
      '${_artifactDirectory.path}/apply-look-eye-reaction-seed-4-trace.json',
    );
    final trace = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final metadata = trace['metadata']! as Map<String, Object?>;
    final samples = (trace['samples']! as List<Object?>)
        .cast<Map<String, Object?>>();

    expect(metadata['seed'], applyLookCaptureSeed);
    expect(metadata['speed'], applyLookCaptureSpeed);
    expect(metadata['fps'], applyLookSuccessSpec.framesPerSecond);
    expect(
      metadata['durationMs'],
      applyLookSuccessSpec.duration.inMilliseconds,
    );
    expect(metadata['frameCount'], applyLookSuccessSpec.frameCount);
    expect(metadata['captureFormat'], 'animated-gif-fallback-no-ffmpeg');
    expect(samples.first['timeMs'], 0);
    expect(
      samples.last['timeMs'],
      applyLookSuccessSpec.duration.inMilliseconds,
    );
    expect(metadata['stateTraceDigest'], fnv1a64(jsonEncode(samples)));
    expect(
      samples.map((sample) => sample['applicationStatus']),
      containsAllInOrder(['ready', 'applying', 'applied']),
    );
  });

  test('capture leaves no PNG sequence and is absent from app assets', () {
    final pngFiles = _artifactDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.png'))
        .toList();
    expect(
      pngFiles.map((file) => file.uri.pathSegments.last),
      unorderedEquals(const [
        'apply-look-reactions-contact-sheet.png',
        'apply-look-lifecycle-contact-sheet.png',
      ]),
    );
    expect(image.decodePng(pngFiles.first.readAsBytesSync()), isNotNull);
    expect(
      _artifactDirectory.listSync(recursive: true).whereType<Directory>(),
      isEmpty,
    );
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('artifacts/apply-look-eye-reaction-v1')));
    expect(pubspec, isNot(contains('apply_look_realtime_capture')));
    expect(
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.readAsStringSync().contains('apply_look_realtime_capture'),
          ),
      isEmpty,
    );
  });
}

List<Map<String, Object?>> _deterministicTrace() {
  final definition = _productionDefinition();
  final player = EyeMotionPlayer(
    behaviourEngine: EyeBehaviourEngine(
      math.Random(applyLookCaptureSeed),
      initialMood: EyeEmotion.neutral,
    ),
    definition: definition,
    initialMood: EyeEmotion.neutral,
    initialClip: resolveInitialEyeMotionClip(definition),
    behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
  )..setSpeed(applyLookCaptureSpeed);
  final coordinator = LookEyeReactionCoordinator(
    player: player,
    refresh: () {},
  );
  final trace = ApplyLookTraceBuilder(spec: applyLookSuccessSpec);
  var status = LookApplicationStatus.ready;
  for (var frame = 0; frame < applyLookSuccessSpec.frameCount; frame++) {
    if (frame > 0) player.advance(applyLookSuccessSpec.frameDelta(frame));
    if (frame == 30) {
      status = LookApplicationStatus.applying;
      coordinator.sync(status, reducedMotion: false);
    } else if (frame == 75) {
      status = LookApplicationStatus.applied;
      coordinator.sync(status, reducedMotion: false);
    }
    if (frame % 3 == 0) {
      trace.sample(player, applyLookSuccessSpec.frameTime(frame), status);
    }
  }
  player.advance(
    applyLookSuccessSpec.duration -
        applyLookSuccessSpec.frameTime(applyLookSuccessSpec.frameCount - 1),
  );
  trace.sample(player, applyLookSuccessSpec.duration, status);
  return trace.samples;
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

const _specs = [
  applyLookSuccessSpec,
  applyLookFailureRetrySpec,
  applyLookLifecycleSpec,
];
