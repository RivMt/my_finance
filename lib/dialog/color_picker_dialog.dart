import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Selects a color from a picker or a recent-color palette.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.palettes = const [],
    this.paletteSize = 32,
  });

  /// Initially selected color.
  final Color color;

  /// Called whenever the selected color changes.
  final void Function(Color) onColorChanged;

  /// Optional recent colors displayed below the picker.
  final List<Color> palettes;

  /// Diameter of each palette button.
  final double paletteSize;

  @override
  State createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {

  /// Maximum number of recent colors shown.
  final maxPaletteNumber = 10;

  /// Currently selected color.
  Color selected = Colors.white;

  /// Updates and reports the selected color.
  void onColorChanged(Color value) {
    setState(() {
      selected = value;
    });
    widget.onColorChanged(value);
  }

  @override
  void initState() {
    super.initState();
    selected = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColorPicker(
              pickerColor: selected,
              onColorChanged: onColorChanged,
              hexInputBar: true,
              enableAlpha: false,
            ),
            if (widget.palettes.isNotEmpty)
              SizedBox(
                width: ScreenPlanner(context).dialogWidth,
                height: widget.paletteSize * 2,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: math.min(widget.palettes.length, maxPaletteNumber),
                  itemBuilder: (context, index) {
                    final color = widget.palettes[index];
                    return IconButton(
                      icon: Icon(
                        Icons.circle,
                        color: color,
                      ),
                      selectedIcon: Icon(
                        Icons.check_circle,
                        color: color,
                      ),
                      iconSize: widget.paletteSize,
                      isSelected: selected == color,
                      onPressed: () => onColorChanged(color),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selected),
          child: Text(LocaleKeys.confirm.tr()),
        ),
      ],
    );
  }
}
