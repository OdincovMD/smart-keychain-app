@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';
import 'package:smart_keychain_app/domain/content/scene.dart';
import 'package:smart_keychain_app/domain/device/device_connection_status.dart';
import 'package:smart_keychain_app/domain/device/device_snapshot.dart';
import 'package:smart_keychain_app/features/device_home/widgets/companion_stage.dart';
import 'package:smart_keychain_app/features/device_home/widgets/jewel_button.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/status_glyph.dart';
import 'package:smart_keychain_app/features/device_home/widgets/wardrobe_rail.dart';
import 'package:smart_keychain_app/infrastructure/content/built_in_scene_repository.dart';
import 'package:smart_keychain_app/infrastructure/device/virtual_device_engine.dart';
import 'package:smart_keychain_app/l10n/app_localizations.dart';

import '../support/load_app_fonts.dart';

const _background = Color(0xFF0B0A0F);
const _labelColor = Color(0xFFF8F4FA);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);
  tearDown(_resetView);

  testWidgets('Kiss Cut V2.1 character sheet at 240', (tester) async {
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
      find.byKey(const Key('v21_golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_v21_character_sheet_240.png'),
    );
  });

  testWidgets('Kiss Cut V2.1 character sheet at 64', (tester) async {
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
      find.byKey(const Key('v21_golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_v21_character_sheet_64.png'),
    );
  });

  testWidgets('Kiss Cut V2.1 monochrome anatomy', (tester) async {
    await _setSurface(tester, const Size(860, 250));
    await tester.pumpWidget(
      _GoldenSurface(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final mood in KissCutVisualMood.values)
              _MoodTile(mood: mood, diameter: 104, monochrome: true),
          ],
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('v21_golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_v21_monochrome.png'),
    );
  });

  testWidgets('Kiss Cut V2 versus V2.1', (tester) async {
    await _setSurface(tester, const Size(650, 330));
    await tester.pumpWidget(
      const _GoldenSurface(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StyleTile(label: 'KISS CUT V2', style: KissCutRendererStyle.v2),
            _StyleTile(
              label: 'KISS CUT V2.1',
              style: KissCutRendererStyle.v21Pure,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('v21_golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_v2_vs_v21.png'),
    );
  });

  testWidgets('Kiss Cut V2.1 signature detail study', (tester) async {
    await _setSurface(tester, const Size(650, 330));
    await tester.pumpWidget(
      const _GoldenSurface(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StyleTile(
              label: 'PURE KISS CUT',
              style: KissCutRendererStyle.v21Pure,
            ),
            _StyleTile(
              label: '+ RESTRAINED GLINT',
              style: KissCutRendererStyle.v21OpticalGlint,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('v21_golden_surface')),
      matchesGoldenFile('baselines/kiss_cut_v21_signature_detail_study.png'),
    );
  });

  testWidgets('Companion Home V2.1 visual preview', (tester) async {
    await _setSurface(tester, const Size(390, 844));
    final scenes = await BuiltInSceneRepository().getAll();
    final activeScene = scenes.first;
    const snapshot = DeviceSnapshot(
      deviceId: VirtualDeviceEngine.deviceId,
      connectionStatus: DeviceConnectionStatus.ready,
      batteryPercent: 78,
      brightness: 0.8,
      activeSceneId: BuiltInSceneRepository.livingEyesId,
      displayProfile: VirtualDeviceEngine.displayProfile,
      capabilities: VirtualDeviceEngine.capabilities,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: _HomePreview(
          activeScene: activeScene,
          scenes: scenes,
          snapshot: snapshot,
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('v21_home_preview')),
      matchesGoldenFile('baselines/companion_home_kiss_cut_v21_preview.png'),
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
        key: const Key('v21_golden_surface'),
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
                state: KissCutStudyPose.forMood(
                  mood,
                  style: KissCutRendererStyle.v21Pure,
                ),
                visualMoodOverride: mood,
                style: KissCutRendererStyle.v21Pure,
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

final class _StyleTile extends StatelessWidget {
  const _StyleTile({required this.label, required this.style});

  final String label;
  final KissCutRendererStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox.square(
            dimension: 240,
            child: KissCutEyesView(
              state: KissCutStudyPose.forMood(
                KissCutVisualMood.neutral,
                style: style,
              ),
              style: style,
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
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

final class _HomePreview extends StatelessWidget {
  const _HomePreview({
    required this.activeScene,
    required this.scenes,
    required this.snapshot,
  });

  final Scene activeScene;
  final List<Scene> scenes;
  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(ResolvedAppAppearance.obsidian),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                key: const Key('v21_home_preview'),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ТВОЙ КОМПАНЬОН',
                                style: context.chromeKissText.status,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Живой взгляд',
                                style: context.chromeKissText.title.copyWith(
                                  fontFamily: 'NunitoSans',
                                  fontSize: 23,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const StatusGlyph(
                          value: 'Готов',
                          semanticLabel: 'Готов',
                          tone: StatusGlyphTone.connected,
                        ),
                        const SizedBox(width: 8),
                        const StatusGlyph(
                          value: '78%',
                          semanticLabel: 'Заряд 78%',
                          tone: StatusGlyphTone.battery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Transform.translate(
                        offset: const Offset(-6, 0),
                        child: CompanionStage(
                          scene: activeScene,
                          displayProfile: snapshot.displayProfile,
                          snapshot: snapshot,
                          diameter: 310,
                          visualStudyOverride: KissCutEyesView(
                            state: KissCutStudyPose.forMood(
                              KissCutVisualMood.neutral,
                              style: KissCutRendererStyle.v21Pure,
                            ),
                            style: KissCutRendererStyle.v21Pure,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'СПОКОЙНАЯ',
                      textAlign: TextAlign.center,
                      style: context.chromeKissText.status.copyWith(
                        color: context.chromeKiss.materialChampagne,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Сегодня просто рядом.',
                      textAlign: TextAlign.center,
                      style: context.chromeKissText.body.copyWith(
                        color: context.chromeKiss.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    JewelButton(label: 'Сменить образ', onPressed: () {}),
                    const SizedBox(height: 22),
                    WardrobeRail(
                      scenes: scenes,
                      selectedSceneId: activeScene.id,
                      activeSceneId: activeScene.id,
                      enabled: true,
                      isAddingImage: false,
                      onSceneSelected: (_) {},
                      onOpenAll: () {},
                      onAddImage: () {},
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
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
}

void _resetView() {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
  view.resetPhysicalSize();
  view.resetDevicePixelRatio();
}
