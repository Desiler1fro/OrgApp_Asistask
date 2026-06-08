import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'color_palette_grid.dart';

class AddSubjectSheet extends StatefulWidget {
  const AddSubjectSheet({
    required this.usedColorValues,
    required this.suggestedColorValue,
    required this.onSubmit,
    super.key,
  });

  final Set<int> usedColorValues;
  final int suggestedColorValue;
  final Future<bool> Function(String name, int colorValue) onSubmit;

  @override
  State<AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<AddSubjectSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late int _colorValue;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _colorValue = widget.suggestedColorValue;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para la materia.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await widget.onSubmit(name, _colorValue);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _error = 'Ya tienes una materia con ese nombre.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
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
            Text('Nueva materia', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warmGray, width: 1),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Ej. Historia',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.calendarDeadline,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Elige un color',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.graphiteSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
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
                _submitting ? 'Guardando…' : 'Agregar materia',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
