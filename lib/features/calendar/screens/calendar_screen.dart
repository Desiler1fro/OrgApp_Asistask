import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Center(
        child: Text(
          'Próximamente',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.graphiteSoft,
          ),
        ),
      ),
    );
  }
}
