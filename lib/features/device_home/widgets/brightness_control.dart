import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../l10n/app_localizations.dart';

final class BrightnessControl extends StatefulWidget {
  const BrightnessControl({
    required this.value,
    required this.enabled,
    required this.onChangeEnd,
    super.key,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChangeEnd;

  @override
  State<BrightnessControl> createState() => _BrightnessControlState();
}

final class _BrightnessControlState extends State<BrightnessControl> {
  late double _draftValue = widget.value;
  bool _dragging = false;

  @override
  void didUpdateWidget(BrightnessControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value) {
      _draftValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (_draftValue * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.light_mode_rounded, color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.brightness,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                l10n.percentValue(percent),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppColors.amber),
              ),
            ],
          ),
          Slider(
            key: const Key('brightness_slider'),
            value: _draftValue,
            onChangeStart: widget.enabled
                ? (_) => setState(() => _dragging = true)
                : null,
            onChanged: widget.enabled
                ? (value) => setState(() => _draftValue = value)
                : null,
            onChangeEnd: widget.enabled
                ? (value) {
                    setState(() => _dragging = false);
                    widget.onChangeEnd(value);
                  }
                : null,
          ),
          Text(
            l10n.brightnessHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
