import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/features/device_home/widgets/eye_motion_ticker.dart';

const neutralCaptureSeed = 4;
const neutralCaptureSpeed = 1.0;

final class NeutralCaptureSpec {
  const NeutralCaptureSpec({
    required this.name,
    required this.width,
    required this.height,
    required this.framesPerSecond,
    required this.duration,
  });

  final String name;
  final int width;
  final int height;
  final int framesPerSecond;
  final Duration duration;

  int get frameCount =>
      duration.inMicroseconds *
      framesPerSecond ~/
      Duration.microsecondsPerSecond;

  Duration frameTime(int frameIndex) => Duration(
    microseconds:
        frameIndex * Duration.microsecondsPerSecond ~/ framesPerSecond,
  );

  Duration frameDelta(int frameIndex) {
    if (frameIndex <= 0) return Duration.zero;
    return frameTime(frameIndex) - frameTime(frameIndex - 1);
  }

  int gifDelayCentiseconds(int frameIndex) {
    final start = frameIndex * 100 ~/ framesPerSecond;
    final end = (frameIndex + 1) * 100 ~/ framesPerSecond;
    return end - start;
  }
}

const neutralCloseupSpec = NeutralCaptureSpec(
  name: 'neutral-living-idle-closeup-seed-4',
  width: 240,
  height: 240,
  framesPerSecond: 30,
  duration: Duration(seconds: 30),
);

const neutralCloseupPreviewSpec = NeutralCaptureSpec(
  name: 'neutral-living-idle-closeup-preview',
  width: 240,
  height: 240,
  framesPerSecond: 15,
  duration: Duration(seconds: 30),
);

const neutralHomeSpec = NeutralCaptureSpec(
  name: 'neutral-living-idle-home-390x844-seed-4',
  width: 390,
  height: 844,
  framesPerSecond: 15,
  duration: Duration(seconds: 20),
);

const neutralBlinkSpec = NeutralCaptureSpec(
  name: 'neutral-blink-gestures',
  width: 240,
  height: 240,
  framesPerSecond: 30,
  duration: Duration(seconds: 8),
);

const neutralSignatureSpec = NeutralCaptureSpec(
  name: 'neutral-signature-reactions',
  width: 240,
  height: 240,
  framesPerSecond: 30,
  duration: Duration(seconds: 10),
);

final class StreamingGifCapture {
  StreamingGifCapture(this.spec)
    : _encoder = image.GifEncoder(
        numColors: 128,
        quantizerType: image.QuantizerType.octree,
        dither: image.DitherKernel.none,
        dispose: 1,
      );

  final NeutralCaptureSpec spec;
  final image.GifEncoder _encoder;
  var _frames = 0;

  int get frameCount => _frames;

  void addRgbaFrame(ByteData rgba, int frameIndex) {
    if (frameIndex != _frames) {
      throw StateError(
        'Non-sequential ${spec.name} frame: expected $_frames, got $frameIndex.',
      );
    }
    _encoder.addFrame(
      image.Image.fromBytes(
        width: spec.width,
        height: spec.height,
        bytes: rgba.buffer,
        bytesOffset: rgba.offsetInBytes,
        numChannels: 4,
        rowStride: spec.width * 4,
        order: image.ChannelOrder.rgba,
      ),
      duration: spec.gifDelayCentiseconds(frameIndex),
    );
    _frames++;
  }

  File finish(Directory outputDirectory) {
    if (_frames != spec.frameCount) {
      throw StateError(
        '${spec.name} contains $_frames frames; expected ${spec.frameCount}.',
      );
    }
    final bytes = _encoder.finish();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('${spec.name} GIF encoder returned no bytes.');
    }
    outputDirectory.createSync(recursive: true);
    final file = File('${outputDirectory.path}/${spec.name}.gif');
    file.writeAsBytesSync(bytes);
    return file;
  }
}

Future<ByteData> captureBoundaryRgba(
  WidgetTester tester,
  Finder boundaryFinder,
  NeutralCaptureSpec spec,
) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    boundaryFinder,
  );
  final bytes = await tester.runAsync(() async {
    final rendered = await boundary.toImage(pixelRatio: 1);
    try {
      if (rendered.width != spec.width || rendered.height != spec.height) {
        throw StateError(
          '${spec.name} rendered ${rendered.width}x${rendered.height}; '
          'expected ${spec.width}x${spec.height}.',
        );
      }
      return await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
    } finally {
      rendered.dispose();
    }
  });
  if (bytes == null) {
    throw StateError('${spec.name} returned no RGBA data.');
  }
  return bytes;
}

void prepareRuntimeForDeterministicCapture(EyeMotionTicker runtime) {
  runtime.pause();
  runtime.player
    ..setSpeed(neutralCaptureSpeed)
    ..resume();
}

void advanceRuntimeFrame(
  EyeMotionTicker runtime,
  NeutralCaptureSpec spec,
  int frameIndex,
) {
  if (frameIndex > 0) runtime.player.advance(spec.frameDelta(frameIndex));
  runtime.refresh();
}

final class NeutralTraceBuilder {
  NeutralTraceBuilder({required this.spec});

  final NeutralCaptureSpec spec;
  final List<Map<String, Object?>> _samples = [];
  final List<Map<String, Object?>> _signatureMoments = [];
  EyeMotionActiveGesture _previousGesture = EyeMotionActiveGesture.none;

  List<Map<String, Object?>> get samples => List.unmodifiable(_samples);

  void sample(EyeMotionPlayer player, Duration time) {
    final state = player.state;
    final diagnostics = player.diagnostics;
    final gesture = diagnostics.activeGesture;
    if (_isSignature(gesture) && gesture != _previousGesture) {
      _signatureMoments.add({
        'timeMs': time.inMilliseconds,
        'gesture': gesture.name,
      });
    }
    _previousGesture = gesture;
    _samples.add({
      'timeMs': time.inMilliseconds,
      'phase': state.motionPhase.name,
      'playerPhase': diagnostics.playerPhase.name,
      'gazeX': _rounded(state.gazeX),
      'gazeY': _rounded(state.gazeY),
      'targetX': _rounded(diagnostics.gazeTargetX),
      'targetY': _rounded(diagnostics.gazeTargetY),
      'leftEyelid': _rounded(state.leftEyelidOpen),
      'rightEyelid': _rounded(state.rightEyelidOpen),
      'pupilScale': _rounded(state.pupilScale),
      'blink': diagnostics.blinkType?.name ?? 'none',
      'gesture': gesture.name,
      'scheduler': diagnostics.schedulerState.name,
    });
  }

  Map<String, Object?> build(EyeMotionPlayer player) {
    final statistics = player.livingIdleStatistics;
    final canonicalSamples = jsonEncode(_samples);
    return {
      'metadata': {
        'seed': neutralCaptureSeed,
        'speed': neutralCaptureSpeed,
        'fps': spec.framesPerSecond,
        'durationMs': spec.duration.inMilliseconds,
        'frameCount': spec.frameCount,
        'frameTimestampRule': 'floor(frameIndex * 1000000 / fps)',
        'runtimeVersion': 'neutral-living-idle-v2',
        'runtimeMode': 'EyeMotionPlayer.neutralLivingIdle',
        'renderer': 'Kiss Cut V2.1 production',
        'captureFormat': 'animated-gif-fallback-no-ffmpeg',
        'gazeTransitions': statistics.gazeTransitions,
        'microSaccadeBursts': statistics.microSaccadeBursts,
        'blinkTypes': {
          'natural': statistics.naturalBlinks,
          'double': statistics.doubleBlinks,
          'slow': statistics.slowBlinks,
        },
        'signatureCount': statistics.signatureMoments,
        'signatureMoments': _signatureMoments,
        'stateTraceDigest': fnv1a64(canonicalSamples),
      },
      'samples': _samples,
    };
  }

  static bool _isSignature(EyeMotionActiveGesture gesture) => switch (gesture) {
    EyeMotionActiveGesture.neutralCuriousGlance ||
    EyeMotionActiveGesture.neutralSoftCenterBlink ||
    EyeMotionActiveGesture.neutralSideHoldReturn => true,
    _ => false,
  };
}

String fnv1a64(String value) {
  final offset = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);
  var hash = offset;
  for (final byte in utf8.encode(value)) {
    hash ^= BigInt.from(byte);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

double _rounded(double value) => (value * 100000).round() / 100000;
