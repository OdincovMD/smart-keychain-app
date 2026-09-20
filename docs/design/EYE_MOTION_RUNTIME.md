# Eye Motion Runtime

## Purpose

The eye runtime gives Chrome Kiss one deterministic motion spine. Flutter owns
one monotonic frame ticker; the domain player owns time, authored clips,
procedural behaviour, interruption, and safety bounds. No `Timer` participates
in eye motion and Riverpod is used only for infrequent debug intents.

The visual thesis remains Chrome Kiss: a glossy black lens, orchid/lilac
material, a recognisable cut-paper eye silhouette, controlled asymmetry, and
small optical highlights. Motion supports character continuity and delight. It
must not become generic ambient movement or compete with task UI.

## Runtime split

- `EyeMotionDefinition` validates the owned interchange format.
- `EyeMotionClipSampler` samples a clip from elapsed time without Flutter.
- `EyeMotionPlayer` is the deterministic state machine and sole composition
  authority.
- `EyeMotionTicker` is a thin Flutter adapter. It forwards monotonic deltas and
  invalidates only the painter/listeners.
- `KissCutEyePainter` owns the parametric silhouette, pupils, gaze, and lid
  occlusion. PNG stretching is not the production motion path.

The player composes each frame in this fixed order:

1. base mood;
2. authored clip;
3. gaze and seeded micro-behaviour;
4. blink;
5. finite-value and geometry clamps.

New commands capture the current interpolated state before retargeting. Mood
changes do the same. Pause and app lifecycle suspension discard the previous
ticker timestamp, so resume never catches up background time. Reduced motion
stops the ticker and displays a stable mood pose.

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

`blinkConfiguration` is optional and typed. When present on a `natural` clip,
the player uses its initial delay, seeded min/max interval, and authored blink
duration. A `suppress` clip retains the configuration for lossless authoring
round-trips but schedules no blink from it.

## Original clips

- `neutral_idle`: the original built-in loop, with soft breathing and sparse
  notice.
- `curious_follow`: anticipation, overshoot, settle, and return.
- `flirty_glance`: asymmetric contact, side glance, and soft return.

These three clips remain built-in Character Study/debug material. The bundled
production asset contains `kiss-idle` and `kiss-flirty-scan`. Home starts
`kiss-idle`; `kiss-flirty-scan` is available only from Character Study for now.
Seeded natural, slow, and double blinks, asymmetric leading lids, gaze
overshoot, rare asymmetry, and pupil response are procedural overlays.

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
