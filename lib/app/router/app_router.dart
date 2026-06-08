import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/subject_repository_provider.dart';
import '../../features/day_limits/screens/day_limits_screen.dart';
import '../../features/manage_subjects/screens/manage_subjects_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(subjectsStreamProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final subjects = ref.read(subjectsStreamProvider);
      return subjects.maybeWhen(
        data: (list) {
          final atOnboarding = state.matchedLocation == '/onboarding';
          if (list.isEmpty && !atOnboarding) return '/onboarding';
          if (list.isNotEmpty && atOnboarding) return '/';
          return null;
        },
        orElse: () => null,
      );
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
        routes: [
          GoRoute(
            path: 'manage-subjects',
            builder: (context, state) => const ManageSubjectsScreen(),
          ),
          GoRoute(
            path: 'day-limits',
            builder: (context, state) => const DayLimitsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});
