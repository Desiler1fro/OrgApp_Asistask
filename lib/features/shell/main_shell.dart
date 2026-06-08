import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../add_task/screens/add_task_screen.dart';
import '../calendar/screens/calendar_screen.dart';
import '../task_list/screens/task_list_screen.dart';

enum _ShellMenuAction { manageSubjects, dayLimits, notifications }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final PageController _pageController = PageController();

  static const _accents = <Color>[
    AppColors.tab1Accent,
    AppColors.tab2Accent,
    AppColors.tab3Accent,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
  }

  void _onMenuSelected(_ShellMenuAction action) {
    switch (action) {
      case _ShellMenuAction.manageSubjects:
        context.go('/manage-subjects');
      case _ShellMenuAction.dayLimits:
        context.go('/day-limits');
      case _ShellMenuAction.notifications:
        context.go('/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              _KeepAlive(child: AddTaskScreen()),
              _KeepAlive(child: TaskListScreen()),
              _KeepAlive(child: CalendarScreen()),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: _ShellMenuButton(
                  accentColor: _accents[_index],
                  onSelected: _onMenuSelected,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        selectedItemColor: _accents[_index],
        unselectedItemColor: AppColors.graphiteSoft,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_rounded),
            label: 'Listado',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _ShellMenuButton extends StatelessWidget {
  const _ShellMenuButton({
    required this.accentColor,
    required this.onSelected,
  });

  final Color accentColor;
  final ValueChanged<_ShellMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 1,
      child: PopupMenuButton<_ShellMenuAction>(
        tooltip: 'Más opciones',
        icon: Icon(Icons.more_vert_rounded, color: accentColor),
        onSelected: onSelected,
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _ShellMenuAction.manageSubjects,
            child: Row(
              children: [
                Icon(Icons.school_outlined, size: 20),
                SizedBox(width: 12),
                Text('Gestionar materias'),
              ],
            ),
          ),
          PopupMenuItem(
            value: _ShellMenuAction.dayLimits,
            child: Row(
              children: [
                Icon(Icons.event_available_outlined, size: 20),
                SizedBox(width: 12),
                Text('Tope por día'),
              ],
            ),
          ),
          PopupMenuItem(
            value: _ShellMenuAction.notifications,
            child: Row(
              children: [
                Icon(Icons.notifications_none_rounded, size: 20),
                SizedBox(width: 12),
                Text('Notificaciones'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
