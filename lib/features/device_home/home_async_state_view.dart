import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/chrome_kiss_theme.dart';
import '../../domain/eyes/eye_emotion.dart';
import '../../l10n/app_localizations.dart';
import '../shared/chrome_kiss_fidelity_frame.dart';
import 'widgets/jewel_button.dart';
import 'widgets/kiss_cut_eye_renderer.dart';
import 'widgets/procedural_eyes_view.dart';

enum HomeAsyncStateKind {
  initialLoading,
  contentLoading,
  sceneLibraryFailure,
  activeSceneFailure,
  snapshotUnavailable,
}

final class HomeAsyncStateView extends StatefulWidget {
  const HomeAsyncStateView({
    required this.kind,
    this.retryBusy = false,
    this.onRetry,
    this.onReturnToDiscovery,
    super.key,
  });

  final HomeAsyncStateKind kind;
  final bool retryBusy;
  final VoidCallback? onRetry;
  final VoidCallback? onReturnToDiscovery;

  @override
  State<HomeAsyncStateView> createState() => _HomeAsyncStateViewState();
}

final class _HomeAsyncStateViewState extends State<HomeAsyncStateView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opticalController;
  bool? _reduceMotion;

  bool get _loading =>
      widget.kind == HomeAsyncStateKind.initialLoading ||
      widget.kind == HomeAsyncStateKind.contentLoading;

  @override
  void initState() {
    super.initState();
    _opticalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _syncMotion();
  }

  @override
  void didUpdateWidget(HomeAsyncStateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) _syncMotion();
  }

  void _syncMotion() {
    if (_loading && _reduceMotion == false) {
      _opticalController.repeat();
    } else {
      _opticalController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _opticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = _copyFor(l10n, widget.kind);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ChromeKissFidelityFrame(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const Key('home_async_state_scroll'),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 12,
              ),
              child: IntrinsicHeight(
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: copy.semantics,
                  child: Column(
                    key: Key('home_async_${widget.kind.name}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ChromeKissReferenceStatusBar(),
                      const SizedBox(height: 8),
                      _HomeAsyncHeader(copy: copy),
                      const SizedBox(height: 12),
                      Center(
                        child: _HomeLoadingStage(
                          loading: _loading,
                          progress: _opticalController,
                          staticPose: reduceMotion,
                          semanticsLabel: copy.stageSemantics,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        copy.title,
                        textAlign: TextAlign.center,
                        style: context.chromeKissText.display.copyWith(
                          fontSize: 35,
                          height: 1.04,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.body,
                        textAlign: TextAlign.center,
                        style: context.chromeKissText.body.copyWith(
                          color: context.chromeKiss.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      if (_loading)
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 4),
                          child: ExcludeSemantics(
                            child: Row(
                              key: const Key('home_loading_hint'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: context.chromeKiss.accentOptical,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    l10n.homeLoadingHint,
                                    textAlign: TextAlign.center,
                                    style: context.chromeKissText.status
                                        .copyWith(
                                          color:
                                              context.chromeKiss.textSecondary,
                                          fontSize: 11,
                                          letterSpacing: 0.45,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 20),
                        JewelButton(
                          key: const Key('home_async_retry_button'),
                          label: l10n.retry,
                          busy: widget.retryBusy,
                          style: JewelButtonStyle.hero,
                          onPressed: widget.retryBusy ? null : widget.onRetry,
                        ),
                        if (widget.onReturnToDiscovery != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            key: const Key('home_async_return_to_discovery'),
                            onPressed: widget.onReturnToDiscovery,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              foregroundColor: context.chromeKiss.textPrimary,
                              side: BorderSide(
                                color: context.chromeKiss.divider,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(l10n.returnToDeviceSearch),
                          ),
                        ],
                      ],
                      const SizedBox(height: 14),
                      const Align(child: ChromeKissHomeIndicator()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class HomeContentLoadingIndicator extends StatefulWidget {
  const HomeContentLoadingIndicator({super.key});

  @override
  State<HomeContentLoadingIndicator> createState() =>
      _HomeContentLoadingIndicatorState();
}

final class _HomeContentLoadingIndicatorState
    extends State<HomeContentLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final label = AppLocalizations.of(context).homeContentRefreshing;
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSecondary.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.divider),
            boxShadow: [
              BoxShadow(
                color: colors.lens.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  key: Key(
                    _reduceMotion == true
                        ? 'home_content_glint_static'
                        : 'home_content_glint_animated',
                  ),
                  width: 34,
                  height: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: ColoredBox(
                      color: colors.divider,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Align(
                          alignment: Alignment(-1 + _controller.value * 2, 0),
                          child: child,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.accentOptical,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const SizedBox(width: 12, height: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: context.chromeKissText.status.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _HomeAsyncHeader extends StatelessWidget {
  const _HomeAsyncHeader({required this.copy});

  final _HomeAsyncCopy copy;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final l10n = AppLocalizations.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 17;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceSecondary.withValues(alpha: 0.72),
                border: Border.all(color: colors.divider),
              ),
              child: Icon(copy.icon, color: colors.materialChrome, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deviceHomeEyebrow,
                    style: context.chromeKissText.status.copyWith(
                      color: colors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.companionName,
                    style: context.chromeKissText.title.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: largeText ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            mainAxisSize: largeText ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(copy.icon, size: 13, color: colors.materialChampagne),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  copy.status,
                  style: context.chromeKissText.status.copyWith(
                    color: colors.textPrimary,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _HomeLoadingStage extends StatelessWidget {
  const _HomeLoadingStage({
    required this.loading,
    required this.progress,
    required this.staticPose,
    required this.semanticsLabel,
  });

  final bool loading;
  final Animation<double> progress;
  final bool staticPose;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.chromeKiss;
    final scene = _HomeOpticalScene(
      rim: colors.materialChrome,
      accent: loading ? colors.accentPrimary : colors.materialChampagne,
      optical: colors.accentOptical,
      loading: loading,
      staticPose: staticPose,
    );
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const Key('home_async_companion'),
          dimension: 268,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.lens,
                    border: Border.all(
                      color: colors.materialChrome.withValues(alpha: 0.72),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.lens.withValues(alpha: 0.36),
                        blurRadius: 22,
                        spreadRadius: -5,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Opacity(
                      opacity: loading ? 0.72 : 0.58,
                      child: ProceduralEyesView(
                        initialEmotion: loading
                            ? EyeEmotion.sleepy
                            : EyeEmotion.neutral,
                        animate: false,
                        rendererVariant: EyeRendererVariant.figmaJewelry,
                      ),
                    ),
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  key: Key(
                    loading && !staticPose
                        ? 'home_loading_optical_animated'
                        : 'home_loading_optical_static',
                  ),
                  painter: _HomeOpticalPainter(scene, progress: progress),
                  isComplex: false,
                  willChange: loading && !staticPose,
                ),
              ),
              if (!loading)
                Center(
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceSecondary.withValues(alpha: 0.9),
                      border: Border.all(color: colors.materialChampagne),
                    ),
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: colors.textPrimary,
                      size: 21,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class _HomeOpticalScene {
  const _HomeOpticalScene({
    required this.rim,
    required this.accent,
    required this.optical,
    required this.loading,
    required this.staticPose,
  });

  final Color rim;
  final Color accent;
  final Color optical;
  final bool loading;
  final bool staticPose;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HomeOpticalScene &&
          rim == other.rim &&
          accent == other.accent &&
          optical == other.optical &&
          loading == other.loading &&
          staticPose == other.staticPose;

  @override
  int get hashCode => Object.hash(rim, accent, optical, loading, staticPose);
}

final class _HomeOpticalPainter extends CustomPainter {
  _HomeOpticalPainter(this.scene, {required Animation<double> progress})
    : _progress = progress,
      super(repaint: progress);

  final _HomeOpticalScene scene;
  final Animation<double> _progress;
  final Paint _rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _tracePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _glintPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final phase = scene.staticPose
        ? -math.pi * 0.72
        : _progress.value * math.pi * 2;
    final pulse = scene.loading && !scene.staticPose
        ? 0.58 + math.sin(_progress.value * math.pi * 2) * 0.16
        : 0.62;

    _rimPaint
      ..strokeWidth = 1.2
      ..color = scene.rim.withValues(alpha: 0.62);
    canvas.drawCircle(center, radius, _rimPaint);

    _tracePaint
      ..strokeWidth = scene.loading ? 4 : 3
      ..color = scene.accent.withValues(alpha: pulse);
    canvas.drawArc(
      bounds,
      phase,
      scene.loading ? math.pi * 1.16 : math.pi * 0.72,
      false,
      _tracePaint,
    );

    final dotAngle = phase + (scene.loading ? math.pi * 1.16 : math.pi * 0.72);
    _glintPaint.color = scene.optical.withValues(
      alpha: scene.loading ? 1 : 0.78,
    );
    canvas.drawCircle(
      Offset(
        center.dx + math.cos(dotAngle) * radius,
        center.dy + math.sin(dotAngle) * radius,
      ),
      scene.loading ? 4.5 : 3.5,
      _glintPaint,
    );
  }

  @override
  bool shouldRepaint(_HomeOpticalPainter oldDelegate) =>
      oldDelegate.scene != scene;
}

final class _HomeAsyncCopy {
  const _HomeAsyncCopy({
    required this.status,
    required this.title,
    required this.body,
    required this.semantics,
    required this.stageSemantics,
    required this.icon,
  });

  final String status;
  final String title;
  final String body;
  final String semantics;
  final String stageSemantics;
  final IconData icon;
}

_HomeAsyncCopy _copyFor(AppLocalizations l10n, HomeAsyncStateKind kind) {
  return switch (kind) {
    HomeAsyncStateKind.initialLoading => _HomeAsyncCopy(
      status: l10n.homeInitialLoadingStatus,
      title: l10n.homeInitialLoadingTitle(l10n.companionName),
      body: l10n.homeInitialLoadingBody,
      semantics: l10n.homeInitialLoadingSemantics,
      stageSemantics: l10n.homeInitialLoadingSemantics,
      icon: Icons.bedtime_outlined,
    ),
    HomeAsyncStateKind.contentLoading => _HomeAsyncCopy(
      status: l10n.homeContentLoadingStatus,
      title: l10n.homeContentLoadingTitle,
      body: l10n.homeContentLoadingBody,
      semantics: l10n.homeContentLoadingSemantics,
      stageSemantics: l10n.homeContentLoadingSemantics,
      icon: Icons.auto_awesome_rounded,
    ),
    HomeAsyncStateKind.sceneLibraryFailure => _HomeAsyncCopy(
      status: l10n.homeSceneLibraryErrorStatus,
      title: l10n.homeSceneLibraryErrorTitle,
      body: l10n.homeSceneLibraryErrorBody,
      semantics: l10n.homeSceneLibraryErrorTitle,
      stageSemantics: l10n.homeSceneLibraryErrorTitle,
      icon: Icons.style_outlined,
    ),
    HomeAsyncStateKind.activeSceneFailure => _HomeAsyncCopy(
      status: l10n.homeActiveSceneErrorStatus,
      title: l10n.homeActiveSceneErrorTitle,
      body: l10n.homeActiveSceneErrorBody,
      semantics: l10n.homeActiveSceneErrorTitle,
      stageSemantics: l10n.homeActiveSceneErrorTitle,
      icon: Icons.visibility_off_outlined,
    ),
    HomeAsyncStateKind.snapshotUnavailable => _HomeAsyncCopy(
      status: l10n.homeSnapshotErrorStatus,
      title: l10n.homeSnapshotErrorTitle,
      body: l10n.homeSnapshotErrorBody,
      semantics: l10n.homeSnapshotErrorSemantics,
      stageSemantics: l10n.homeSnapshotErrorSemantics,
      icon: Icons.link_off_rounded,
    ),
  };
}
