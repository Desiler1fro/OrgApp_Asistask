import 'package:flutter/material.dart';

class SubjectDot extends StatelessWidget {
  const SubjectDot({
    required this.color,
    this.size = 14,
    super.key,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
