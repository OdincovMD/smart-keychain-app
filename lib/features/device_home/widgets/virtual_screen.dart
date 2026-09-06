import 'package:flutter/material.dart';

import '../../../domain/content/scene.dart';
import '../../../domain/device/device_snapshot.dart';
import '../../../domain/device/display_profile.dart';
import 'scene_renderer.dart';

final class VirtualScreen extends StatelessWidget {
  const VirtualScreen({
    required this.scene,
    required this.displayProfile,
    required this.snapshot,
    super.key,
  });

  final Scene scene;
  final DisplayProfile displayProfile;
  final DeviceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return AspectRatio(
      aspectRatio: displayProfile.aspectRatio,
      child: ClipOval(
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: duration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(scene.id),
                  child: SceneRenderer(
                    scene: scene,
                    animate: true,
                    displayProfile: displayProfile,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedContainer(
                  duration: duration,
                  color: Colors.black.withValues(
                    alpha: (1 - snapshot.brightness).clamp(0.0, 1.0),
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
