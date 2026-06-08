import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../state/onboarding_notifier.dart';
import 'liking_selector.dart';
import 'subject_dot.dart';

class OnboardingStepLiking extends ConsumerWidget {
  const OnboardingStepLiking({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InkResponse(
                  onTap: state.saving ? null : onBack,
                  radius: 22,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.graphite,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '¿Cuánto te gusta cada una?',
              style: textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Usamos esta preferencia para sugerirte el mejor orden de tus tareas.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.graphiteSoft,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: state.subjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final s = state.subjects[i];
                  return _LikingRow(
                    name: s.name,
                    color: Color(s.colorValue),
                    liking: s.liking,
                    onChanged: (v) => notifier.setLiking(i, v),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tab2Accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: AppColors.warmGray,
                disabledForegroundColor: Colors.white,
              ),
              onPressed:
                  (notifier.canFinish && !state.saving) ? notifier.persist : null,
              child: state.saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Listo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikingRow extends StatelessWidget {
  const _LikingRow({
    required this.name,
    required this.color,
    required this.liking,
    required this.onChanged,
  });

  final String name;
  final Color color;
  final int liking;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SubjectDot(color: color, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LikingSelector(
            value: liking,
            color: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
