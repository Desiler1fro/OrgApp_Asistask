import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../state/add_task_state.dart';

class PugMascot extends StatelessWidget {
  const PugMascot({
    required this.mood,
    this.size = 160,
    super.key,
  });

  final PugMood mood;
  final double size;

  static const _assetByMood = {
    PugMood.idle: 'assets/images/pug_idle.png',
    PugMood.happy: 'assets/images/pug_happy.png',
    PugMood.celebrate: 'assets/images/pug_celebrate.png',
  };

  @override
  Widget build(BuildContext context) {
    Widget pug = SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetByMood[mood]!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );

    switch (mood) {
      case PugMood.idle:
        pug = pug
            .animate(
              key: const ValueKey('pug-idle'),
              onPlay: (c) => c.repeat(reverse: true),
            )
            .scaleXY(
              begin: 1,
              end: 1.03,
              duration: 1800.ms,
              curve: Curves.easeInOut,
            );
        break;
      case PugMood.happy:
        pug = pug
            .animate(key: const ValueKey('pug-happy'))
            .scaleXY(
              begin: 1,
              end: 1.12,
              duration: 220.ms,
              curve: Curves.easeOut,
            )
            .then()
            .scaleXY(
              begin: 1.12,
              end: 1,
              duration: 260.ms,
              curve: Curves.easeIn,
            );
        break;
      case PugMood.celebrate:
        pug = pug
            .animate(
              key: const ValueKey('pug-celebrate'),
              onPlay: (c) => c.repeat(),
            )
            .moveY(
              begin: 0,
              end: -16,
              duration: 360.ms,
              curve: Curves.easeOut,
            )
            .then()
            .moveY(
              begin: -16,
              end: 0,
              duration: 320.ms,
              curve: Curves.easeIn,
            );
        break;
    }

    return pug;
  }
}
