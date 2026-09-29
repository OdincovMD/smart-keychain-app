# Eye Motion Runtime

## Purpose

Chrome Kiss uses one deterministic motion spine for both authored reactions and
Neutral Living Idle V2. Flutter owns one monotonic frame ticker;
`EyeMotionPlayer` owns time, composition, interruption, and the final safety
boundary. `EyeBehaviourEngine` owns seeded behaviour planning. No `Timer`,
per-layer ticker, per-frame provider write, or second renderer/runtime is part
of eye motion.

The visual thesis remains Chrome Kiss: glossy black lens, orchid/lilac material,
recognisable Kiss Cut silhouettes, controlled asymmetry, and small optical
highlights. Motion adds quiet attention and character without competing with
task UI.

## Runtime ownership

- `EyeMotionDefinition` validates the owned interchange format.
- `EyeMotionClipSampler` samples authored clips from elapsed time without
  Flutter.
- `NeutralLivingIdlePlanner` is a pure-Dart, delta-driven seeded planner. Its
  only entropy boundary is an injected `Random` owned by
  `EyeBehaviourEngine`.
- `EyeMotionPlayer` is the sole composition and interruption authority.
- `EyeMotionTicker` is the only frame clock. It forwards monotonic deltas and
  invalidates painter/listeners only.
- `KissCutEyePainter` remains the V2.1 renderer owner. Neutral V2 changes state,
  not anatomy, motion JSON, or paint construction.
- Riverpod carries infrequent Character Study/debug intents only; it is not a
  frame transport.

Home opts into `EyeMotionBehaviourMode.neutralLivingIdle` for its production
hero. Pairing, loading, recovery, lifecycle-controlled states, static content,
and embedded previews retain their existing controlled/static contracts.
Character Study explicitly opts into the same V2 mode.

## Fixed frame composition

Every Neutral V2 frame follows this order:

1. Neutral base mood;
2. authored clip or foreground reaction;
3. ambient gaze;
4. micro-saccades;
5. eyelid/gaze coupling;
6. blink;
7. pupil micro-variation;
8. controlled asymmetry;
9. finite-value and geometry safety clamps;
10. the existing Kiss Cut V2.1 painter.

A foreground authored clip, forced gaze, blink gesture, or signature always has
priority. While one is active, ambient scheduling is frozen: its dwell, blink,
and signature clocks do not advance and missed events are not replayed later.
Completion captures the current interpolated state and blends back to neutral,
so resume does not snap.

## Neutral Living Idle V2

Ambient gaze uses weighted center, lateral, and gentle vertical interest points.
Targets have unequal dwell times and avoid immediate repetition. A bounded,
slightly underdamped spring supplies travel and a small settle overshoot;
substeps are capped at 16 ms so a long caller delta cannot destabilise it.
The Neutral polish uses stiffness `30.0` and damping `8.25`. Ambient gaze is
bounded to `x ±0.72`, `y ±0.42`.

Micro-saccades occur as short one-to-three event bursts during dwell. They are
independently bounded to `x ±0.045`, `y ±0.035` and can be disabled without
changing the main gaze target. Individual movements last 56–92 ms.

Blink scheduling is irregular and seeded. Ambient scheduling selects only:

- natural blink: fast asymmetric close, short closed phase, softer reopen;
- double blink: a natural first blink and a shorter opposite-leading second;
- slow blink: deliberately longer close, hold, and reopen.

Wink is debug-only and is never selected by the ambient scheduler. A forced
blink defers the next ambient blink to prevent an immediate duplicate.

Pupil micro-variation is smooth seeded value noise, normally within
`0.985–1.015` before authored/mood response. Eyelid openness and expression tilt
receive slower, smaller independent asymmetry noise. All composed values are
clamped at the player boundary before reaching V2.1.

Neutral has three rare authored signatures: curious glance, soft center blink,
and side-hold-return. The initial seeded request window is 19–43 seconds; later
windows are 21–49 seconds. A scheduled signature waits for at least 900 ms of
settled dwell and a calm-center pose (`|x| ≤ 0.1`, `|y| ≤ 0.1`) before entering
the existing player action/interruption path. It never creates a parallel
scheduler or renderer.

## Determinism, lifecycle, and reduced motion

A fixed seed plus the same delta sequence produces the same gaze targets,
blink choices, signatures, and final states. Natural mode reads the app-owned
random source. Character Study may supply an arbitrary integer seed and can
restart that exact seed; replacing it stops the old ticker before the new one
starts, so only one ticker is active.

Pause, app lifecycle suspension, and navigation discard the previous ticker
timestamp. Resume receives only the new foreground delta; background time is
never caught up. Appearance rebuilds and transient sheets preserve runtime
identity. Leaving the surface disposes the ticker; returning creates one
replacement.

Reduced motion stops the ticker and holds a stable mood pose. It does not run
ambient gaze, scheduled blinks, signatures, or hidden catch-up work.

## Character Study workflow

Character Study is the production V2 motion lab. It exposes:

- built-in and bundled production definitions;
- playback at `0.5×`, `1×`, `2×`, and `4×`, play/pause, and clip restart;
- independent ambient gaze, micro-saccade, blink, pupil, and asymmetry toggles;
- forced natural/double/slow blinks and debug-only wink;
- forced left/right gaze and all three neutral signatures;
- arbitrary integer seed, natural entropy, and restart-same-seed;
- live phase, target/current gaze, active gesture, blink type, pupil, and
  scheduler diagnostics.

The controls change the existing engine/player only. They do not create a
second runtime and are not persisted as product settings.

## Verification contract

Domain coverage includes same-seed/delta determinism, different-seed
divergence, non-repeating target selection, per-layer bounds and switches,
blink profile separation, foreground interruption/resume, a fixed 60-second
trace summary, and a ten-simulated-minute finite/bounds run.

The reference seed `4` at 16 ms steps for 60 seconds currently produces 16 gaze
transitions, 10 micro-saccade bursts, 9 natural blinks, 1 double blink, no slow
blink, and 1 signature moment. These counts are a regression fixture, not a
product-frequency promise; forced capture separately covers every blink and
signature type.

Golden review uses 16 sequential frames from that seed at both 240 px and the
64 px device-like scale, plus one natural/double/slow/wink gesture sheet. Widget
coverage verifies Home opt-in, reduced motion, lifecycle pause/resume without
catch-up, runtime identity across rebuild/sheet changes, seed replacement,
ticker disposal, and one replacement ticker after return.

## Offline realtime capture

`tool/neutral_realtime_capture_test.dart` is an explicit, test-only recorder.
It mounts the production V2.1 widget (and the full Obsidian Home for the Home
capture), stops the wall-clock ticker, resumes the same `EyeMotionPlayer`, and
advances it with rational fixed timestamps:

```text
frameTime = floor(frameIndex * 1,000,000 / FPS) microseconds
```

Each output frame follows exactly one next timestamp; no sleep, skipped runtime
state, codec interpolation, second behaviour implementation, per-frame provider
state, or temporary PNG sequence is used. Forced gestures enter through
`EyePreviewController`, the same production command path used by Character
Study. RGBA frames are read from `RepaintBoundary` and streamed into the dev
encoder, so memory does not grow with an uncompressed frame sequence.

The capture is enabled explicitly and is absent from the Flutter asset bundle:

```sh
NEUTRAL_REALTIME_CAPTURE_OUTPUT=artifacts/neutral-living-idle-v2/realtime \
.fvm/flutter_sdk/bin/flutter test \
tool/neutral_realtime_capture_test.dart
```

The current environment has no `ffmpeg`. Final files therefore use the allowed
animated-GIF fallback rather than pretending a GIF is MP4: 30 FPS for close-up,
blink, and signatures; 15 FPS for Home and the small preview. GIF centisecond
delays use a deterministic 3/3/4 pattern at 30 FPS (and 6/7 at 15 FPS), so the
declared frame count sums to the exact capture duration. The companion validation
test checks container metadata, trace determinism/digest, file bounds, bundle
separation, and absence of PNG sequences.

## Owned format

The root object rejects unknown fields and uses:

```json
{
  "schema": "chrome-kiss/eye-motion",
  "schemaVersion": 1,
  "poses": {
    "rest": {"gazeX": 0, "leftEyelidOpen": 1}
  },
  "clips": {
    "neutral_idle": {
      "mode": "loop",
      "blink": "natural",
      "blinkConfiguration": {
        "initialDelayMs": 900,
        "minIntervalMs": 2400,
        "maxIntervalMs": 4600,
        "durationMs": 220
      },
      "steps": [
        {
          "pose": "rest",
          "hold": 1200,
          "transition": 180,
          "style": "easeOut"
        }
      ]
    }
  },
  "metadata": {}
}
```

`hold` and `transition` are integer milliseconds. Values must be finite and
bounded. Limits are 256 KiB JSON, 64 poses, 32 clips, 256 steps per clip,
10 seconds per hold or transition, and 60 seconds per clip. Pose references
must resolve. Validation returns stable typed failures; it does not throw
recoverable format errors.

Playback modes are `once`, `loop`, and `pingPong`. Blink policies are
`natural`, `suppress`, and `authored`. Transition styles are `linear`,
`easeIn`, `easeOut`, `easeInOut`, and `emphasized`.

`blinkConfiguration` is optional and typed. When present on a controlled
`natural` clip, the player uses its initial delay, seeded min/max interval, and
authored blink duration. A `suppress` clip retains the configuration for
lossless authoring round-trips but schedules no blink from it. Neutral Living
Idle V2 keeps the JSON unchanged and composes its own seeded blink layer only
when that mode is explicitly active.

## Original clips

- `neutral_idle`: original built-in loop and Character Study material;
- `curious_follow`: anticipation, overshoot, settle, and return;
- `flirty_glance`: asymmetric contact, side glance, and soft return.

The bundled production asset still contains `kiss-idle` and
`kiss-flirty-scan`. Home starts `kiss-idle`; `kiss-flirty-scan` remains a
Character Study foreground clip. All production JSON and pose authorship remain
unchanged by Neutral Living Idle V2.

## Avatar Definition v1 clean-room adapter

`tool/avatar_lab_motion_converter.dart` is a development-only adapter. The
authoring and curation path is deliberately one-way:

```text
Avatar Lab .avatar.json export
  → local untracked tool/local_inputs export
  → clean-room conversion and provenance review
  → original Chrome Kiss ck_* poses
  → bundled chrome-kiss/eye-motion production asset
  → cached startup loader
  → EyeMotionPlayer
  → Kiss Cut V2.1 renderer
```

Raw exports belong under `tool/local_inputs/`. That directory is ignored by
Git, is not included in the Flutter asset bundle, and must never be committed.
The checked-in schema fixture under `tool/fixtures/` remains available for
converter compatibility tests.

The converter accepts the public `bible-strong/avatar-definition` schema at
`schemaVersion: 1`: root body/colours, nested `expressions.neutral`, expression
and animation order arrays, real animations, object-form blink settings, and
optional names/metadata. It reads only left/right eye `width`, `height`, `x`,
`y`, `angle`, and expression `spacing` into Chrome Kiss. Body geometry,
colours, head, perspective, and source motion hints are validated but not
transferred.

Expressions are normalised relative to the neutral expression, then clamped to
Chrome Kiss runtime values. The converter emits only
`chrome-kiss/eye-motion` version 1.

- average left/right X delta divided by neutral spacing → `gazeX`;
- average Y delta divided by neutral eye height → `gazeY`;
- left/right height ratio → independent eyelid openness;
- average width ratio → `eyeScaleX`;
- differential left/right angle delta → `expressionTilt`;
- spacing is validated but intentionally not transferred.

Avatar transitions map as `smooth → easeInOut`, `snappy → easeOut`, and
`spring → emphasized`. Playback names map directly. The complete blink object
is retained as the owned optional configuration; `enabled: false` additionally
maps to the `suppress` policy.

```sh
dart run tool/avatar_lab_motion_converter.dart \
  path/to/export.avatar.json \
  assets/chrome_kiss/motion/custom.eye-motion.json
```

Exit codes are 64 for usage, 65 for invalid input, and 74 for I/O failure.

The former `avatar_definition_v1_minimal.json` fixture was an internal
compatibility draft and did not match a real Avatar Lab export. The replacement
`avatar_lab_real_export_v1.avatar.json` follows the public schema and contains
only project-authored neutral, curious, flirty, once, and loop data.

No Avatar Lab source code, packages, renderer, runtime, or bundled presets are
copied or linked. Schema compatibility does not grant permission to copy
presets. Timeline authorship and pose authorship are reviewed independently:
animation names, step order, timings, transition styles, blink configuration,
and animation metadata may be curated from a user-authored export, while every
production pose must be project-owned `ck_*` data derived from the Chrome Kiss
runtime and character studies.

The production pack is
`assets/chrome_kiss/motion/chrome_kiss_production_v1.eye-motion.json`. It
contains no Avatar Lab body, colours, unused expressions, or preset pose
values. A policy test rejects known Strobi pose names and Avatar Definition
provenance metadata in production assets.

The bundled JSON is decoded once during bootstrap by the cached loader, before
`runApp`. The resulting immutable definition is shared through Riverpod as an
app-scope value. Asset I/O and decoding never run in `build` or `paint`. A typed
load/decode failure is logged through the existing failure logger and resolves
to `chromeKissEyeMotionDefinition`, so Home always retains a visible eye
fallback.

## Rendering and performance gates

Figma eye layers remain a resting-state reference. V2.1 is the production
runtime renderer because it owns pupils, gaze, and lids parametrically. The
renderer is checked at 240 px and the device-like 64 px scale, including every
mood and seeded extreme geometry.

Profile verification should confirm one active eye ticker, no eye `Timer`, no
per-frame provider writes, painter-only invalidation under the Home screen, and
no unbounded allocation growth. A frame sample should remain within the target
display refresh budget on a profile build; capture the device/model and frame
statistics with the release record rather than treating simulator timing as a
device benchmark.
