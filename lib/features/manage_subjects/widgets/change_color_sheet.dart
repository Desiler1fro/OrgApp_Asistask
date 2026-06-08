import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/entities/subject.dart';
import 'color_palette_grid.dart';

class ChangeColorSheet extends StatefulWidget {
  const ChangeColorSheet({
    required this.subject,
    required this.usedColorValues,
    required this.onSubmit,
    super.key,
  });

  final Subject subject;
  final Set<int> usedColorValues;
  final Future<void> Function(int colorValue) onSubmit;

  @override
  State<ChangeColorSheet> createState() => _ChangeColorSheetState();
}

class _ChangeColorSheetState extends State<ChangeColorSheet> {
  late int _colorValue;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _colorValue = widget.subject.colorValue;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_colorValue == widget.subject.colorValue) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _submitting = true);
    await widget.onSubmit(_colorValue);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.warmGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Cambiar color', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            widget.subject.name,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.graphiteSoft,
            ),
          ),
          const SizedBox(height: 20),
          ColorPaletteGrid(
            selectedValue: _colorValue,
            usedValues: widget.usedColorValues,
            onSelect: (v) => setState(() => _colorValue = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tab1Accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: AppColors.warmGray,
            ),
            onPressed: _submitting ? null : _submit,
            child: Text(
              _submitting ? 'Guardando…' : 'Guardar',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
