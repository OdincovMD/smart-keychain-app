import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/domain/eyes/eye_behaviour_engine.dart';
import 'package:smart_keychain_app/domain/eyes/eye_emotion.dart';
import 'package:smart_keychain_app/domain/eyes/eye_motion_player.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_eye_reaction_lens.dart';
import 'package:smart_keychain_app/features/device_home/widgets/chrome_kiss_production_eyes.dart';
import 'package:smart_keychain_app/features/device_home/widgets/eye_motion_ticker.dart';
import 'package:smart_keychain_app/features/device_home/widgets/kiss_cut_eye_renderer.dart';
import 'package:smart_keychain_app/features/device_home/widgets/procedural_eyes_view.dart';

void main() {
  testWidgets('Home and reaction lens paint one ticker and one player', (
    tester,
  ) async {
    final key = GlobalKey<_RuntimeHarnessState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: _RuntimeHarness(
            key: key,
            builder: (runtime) => Column(
              children: [
                ChromeKissProductionEyes(
                  key: const Key('shared_home_eyes'),
                  scale: ChromeKissEyeScale.hero,
                  mood: KissCutVisualMood.neutral,
                  animate: true,
                  useProductionMotion: true,
                  behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
                  externalRuntime: runtime,
                ),
                ChromeKissEyeReactionLens(
                  key: const Key('shared_reaction_lens'),
                  reactionKey: const Key('shared_reaction_eyes'),
                  size: ChromeKissEyeReactionLensSize.medium,
                  mood: KissCutVisualMood.neutral,
                  animate: true,
                  useProductionMotion: true,
                  runtime: runtime,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final owner = key.currentState!;
    final eyes = tester
        .widgetList<ChromeKissProductionEyes>(
          find.byType(ChromeKissProductionEyes),
        )
        .toList();
    expect(eyes, hasLength(2));
    expect(
      eyes.every((item) => identical(item.externalRuntime, owner.runtime)),
      isTrue,
    );
    expect(find.byType(ProceduralEyesView), findsNWidgets(2));
    expect(owner.runtime.isTicking, isTrue);

    owner.runtime.player.startApplyReaction(EyeApplyReaction.applying);
    owner.runtime.refresh();
    final builds = owner.buildCount;
    await tester.pump(const Duration(milliseconds: 800));

    expect(owner.buildCount, builds);
    expect(
      owner.runtime.player.diagnostics.activeReaction,
      EyeApplyReaction.applying,
    );
    expect(owner.runtime.player.diagnostics.ambientSuspended, isTrue);
  });

  testWidgets('reduced motion holds a reaction pose without a ticker', (
    tester,
  ) async {
    final key = GlobalKey<_RuntimeHarnessState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildAppTheme(),
            home: _RuntimeHarness(
              key: key,
              builder: (runtime) => ChromeKissEyeReactionLens(
                size: ChromeKissEyeReactionLensSize.medium,
                mood: KissCutVisualMood.neutral,
                animate: true,
                useProductionMotion: true,
                runtime: runtime,
              ),
            ),
          ),
        ),
      ),
    );

    final runtime = key.currentState!.runtime;
    runtime.player.showReducedMotionApplyReaction(EyeApplyReaction.success);
    runtime.refresh();
    final pose = runtime.state;
    await tester.pump(const Duration(seconds: 5));

    expect(runtime.isTicking, isFalse);
    expect(runtime.state, pose);
    expect(
      runtime.player.diagnostics.reactionPhase,
      EyeApplyReactionPhase.confirmation,
    );
  });
}

final class _RuntimeHarness extends StatefulWidget {
  const _RuntimeHarness({required this.builder, super.key});

  final Widget Function(EyeMotionTicker runtime) builder;

  @override
  State<_RuntimeHarness> createState() => _RuntimeHarnessState();
}

final class _RuntimeHarnessState extends State<_RuntimeHarness>
    with SingleTickerProviderStateMixin {
  late final EyeMotionTicker runtime;
  var buildCount = 0;

  @override
  void initState() {
    super.initState();
    runtime = EyeMotionTicker(
      vsync: this,
      player: EyeMotionPlayer(
        behaviourEngine: EyeBehaviourEngine(
          math.Random(4),
          initialMood: EyeEmotion.neutral,
        ),
        initialMood: EyeEmotion.neutral,
        behaviourMode: EyeMotionBehaviourMode.neutralLivingIdle,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      runtime.stop(snapToMood: true);
    } else {
      runtime.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    buildCount++;
    return Scaffold(body: Center(child: widget.builder(runtime)));
  }

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }
}
