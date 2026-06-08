import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class ColorPaletteGrid extends StatelessWidget {
  const ColorPaletteGrid({
    required this.selectedValue,
    required this.usedValues,
    required this.onSelect,
    super.key,
  });

  final int? selectedValue;
  final Set<int> usedValues;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        for (final color in AppColors.subjects)
          _ColorSwatch(
            color: color,
            selected: color.toARGB32() == selectedValue,
            inUse: usedValues.contains(color.toARGB32()),
            onTap: () => onSelect(color.toARGB32()),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.inUse,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final bool inUse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.graphite : Colors.transparent,
            width: 3,
          ),
        ),
        child: inUse && !selected
            ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.graphite,
                ),
              )
            : null,
      ),
    );
  }
}
