import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class LikingSelector extends StatelessWidget {
  const LikingSelector({
    required this.value,
    required this.color,
    required this.onChanged,
    super.key,
  });

  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 1; i <= 5; i++)
          _Dot(
            filled: value >= i,
            color: color,
            onTap: () => onChanged(i),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.filled,
    required this.color,
    required this.onTap,
  });

  final bool filled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: filled ? color : AppColors.warmGray,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
