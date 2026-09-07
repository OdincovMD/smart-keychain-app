@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';

import '../support/load_app_fonts.dart';

const _background = Color(0xFF0B0A0F);
const _labelColor = Color(0xFFF8F4FA);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);
  tearDown(_resetView);

  testWidgets('Kiss Cut character sheet at 240', (tester) async {
    await _setSurface(tester, const Size(1080, 620));
    await tester.pumpWidget(
      _GoldenSurface(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final mood in KissCutVisualMood.values)
              _MoodTile(mood: mood, diameter: 240),
          ],
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_character_sheet_240.png'),
    );
  });

  testWidgets('Kiss Cut character sheet at 64', (tester) async {
    await _setSurface(tester, const Size(700, 150));
    await tester.pumpWidget(
      _GoldenSurface(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final mood in KissCutVisualMood.values)
              _MoodTile(mood: mood, diameter: 64, compact: true),
          ],
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_character_sheet_64.png'),
    );
  });

  testWidgets('Kiss Cut monochrome silhouette sheet', (tester) async {
    await _setSurface(tester, const Size(860, 250));
    const moods = [
      KissCutVisualMood.neutral,
      KissCutVisualMood.happy,
      KissCutVisualMood.sleepy,
      KissCutVisualMood.curious,
      KissCutVisualMood.annoyed,
      KissCutVisualMood.surprised,
      KissCutVisualMood.flirty,
    ];
    await tester.pumpWidget(
      _GoldenSurface(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final mood in moods)
              _MoodTile(mood: mood, diameter: 104, monochrome: true),
          ],
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_monochrome_sheet.png'),
    );
  });

  testWidgets('Legacy versus Kiss Cut V2', (tester) async {
    await _setSurface(tester, const Size(650, 330));
    await tester.pumpWidget(
      const ProviderScope(
        child: _GoldenSurface(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ComparisonTile(label: 'LEGACY', legacy: true),
              _ComparisonTile(label: 'KISS CUT V2', legacy: false),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('golden_surface')),
      matchesGoldenFile('baselines/legacy_vs_kiss_cut_v2.png'),
    );
  });

  testWidgets('Kiss Cut restrained colour studies', (tester) async {
    await _setSurface(tester, const Size(840, 330));
    await tester.pumpWidget(
      const _GoldenSurface(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ColourTile(
              label: 'ORCHID / LILAC',
              colourway: KissCutColourway.orchidLilac,
            ),
            _ColourTile(
              label: 'ICY / COOL',
              colourway: KissCutColourway.icyCool,
            ),
            _ColourTile(
              label: 'PEARL / CHAMPAGNE',
              colourway: KissCutColourway.pearlChampagne,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_colour_studies.png'),
    );
  });
}

final class _GoldenSurface extends StatelessWidget {
  const _GoldenSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        key: const Key('golden_surface'),
        color: _background,
        child: Center(child: child),
      ),
    );
  }
}

final class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.diameter,
    this.compact = false,
    this.monochrome = false,
  });

  final KissCutVisualMood mood;
  final double diameter;
  final bool compact;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox.square(
              dimension: diameter,
              child: KissCutEyesView(
                state: KissCutStudyPose.forMood(mood),
                visualMoodOverride: mood,
                monochrome: monochrome,
              ),
            ),
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            mood.name.toUpperCase(),
            maxLines: 1,
            style: TextStyle(
              color: _labelColor,
              fontFamily: 'NunitoSans',
              fontSize: compact ? 8 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? 0 : 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

final class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({required this.label, required this.legacy});

  final String label;
  final bool legacy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox.square(
            dimension: 240,
            child: legacy
                ? const ProceduralEyesView(
                    initialEmotion: EyeEmotion.neutral,
                    animate: false,
                  )
                : KissCutEyesView(
                    state: KissCutStudyPose.forMood(KissCutVisualMood.neutral),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: _labelColor,
            fontFamily: 'NunitoSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

final class _ColourTile extends StatelessWidget {
  const _ColourTile({required this.label, required this.colourway});

  final String label;
  final KissCutColourway colourway;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox.square(
            dimension: 230,
            child: KissCutEyesView(
              state: KissCutStudyPose.forMood(KissCutVisualMood.neutral),
              colourway: colourway,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: _labelColor,
            fontFamily: 'NunitoSans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  final view = tester.view;
  view.devicePixelRatio = 1;
  view.physicalSize = size;
}

void _resetView() {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
  view.resetPhysicalSize();
  view.resetDevicePixelRatio();
}
