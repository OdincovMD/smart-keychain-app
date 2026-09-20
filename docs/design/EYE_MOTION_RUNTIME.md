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

## Original clips

- `neutral_idle`: the production loop, with soft breathing and sparse notice.
- `curious_follow`: anticipation, overshoot, settle, and return.
- `flirty_glance`: asymmetric contact, side glance, and soft return.

The latter two are Character Study/debug material. Seeded natural, slow, and
double blinks, asymmetric leading lids, gaze overshoot, rare asymmetry, and
pupil response are procedural overlays.

## Avatar Definition v1 clean-room adapter

`tool/avatar_lab_motion_converter.dart` is a development-only adapter. It was
implemented from public format documentation and the project-owned minimal
fixture, without copying Avatar Lab source, runtime, or presets. It reads only
left/right eye `width`, `height`, `x`, `y`, `angle`, expression `spacing`,
animation steps, playback mode, transition, and blink intent. `body` and
`colors` are accepted but ignored.

Expressions are normalised relative to the neutral expression, then clamped to
Chrome Kiss runtime values. The converter emits only
`chrome-kiss/eye-motion` version 1.

```sh
dart run tool/avatar_lab_motion_converter.dart INPUT.json OUTPUT.json
```

Exit codes are 64 for usage, 65 for invalid input, and 74 for I/O failure.

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
