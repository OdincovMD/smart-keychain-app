import 'package:flutter/material.dart';

import '../../../app/chrome_kiss_theme.dart';
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
    if (!_dragging &&
        (oldWidget.value != widget.value ||
            oldWidget.enabled != widget.enabled && widget.enabled)) {
      _draftValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.chromeKiss;
    final percent = (_draftValue * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.light_mode_rounded, color: colors.materialChampagne),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.brightness,
                style: context.chromeKissText.body.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.percentValue(percent),
              style: context.chromeKissText.status.copyWith(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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
          style: context.chromeKissText.body.copyWith(
            color: colors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
