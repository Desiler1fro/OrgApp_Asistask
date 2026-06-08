import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/app_colors.dart';
import '../state/add_task_state.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    super.key,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isPug = message.sender == ChatSender.pug;
    final bg = isPug ? AppColors.cream : AppColors.tab1Accent;
    final fg = isPug ? AppColors.graphite : Colors.white;
    final align = isPug ? Alignment.centerLeft : Alignment.centerRight;
    final radius = isPug
        ? const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.graphite.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fg,
                  height: 1.35,
                ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 220.ms)
          .slideX(
            begin: isPug ? -0.15 : 0.15,
            end: 0,
            duration: 240.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
