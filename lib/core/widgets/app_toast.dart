import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// The app's toast: a frosted glass card with a glowing icon tile in the
/// toast's colour and a thin countdown line. Tap or swipe to dismiss.
class AppToast extends StatelessWidget {
  final ToastificationItem item;
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const AppToast({
    super.key,
    required this.item,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final surface = theme.colorScheme.surface;
    void dismiss() => toastification.dismissById(item.id);

    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.horizontal,
        onDismissed: (_) =>
            toastification.dismissById(item.id, showRemoveAnimation: false),
        child: GestureDetector(
          onTap: dismiss,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.30 : 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surface.withValues(alpha: isDark ? 0.78 : 0.90),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: textTheme.titleSmall),
                                    if (message.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        message,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Countdown until the toast closes itself.
                        ToastTimerAnimationBuilder(
                          item: item,
                          builder: (_, value, _) => Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (1 - value).clamp(0, 1),
                              child: Container(height: 3, color: color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
