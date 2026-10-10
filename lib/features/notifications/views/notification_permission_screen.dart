import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_button.dart';

/// Explains why PostPilot wants notifications before the system dialog,
/// which can only be shown once.
class NotificationPermissionScreen extends HookConsumerWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asking = useState(false);
    final navigation = ref.read(navigationServiceProvider.notifier);

    Future<void> allow() async {
      asking.value = true;
      await ref.read(pushServiceProvider.notifier).register();
      if (context.mounted) navigation.pop();
    }

    final textTheme = context.textTheme;

    return AppScaffold(
      showOfflineBanner: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 36,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Know the moment\nyou go live 🚀',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'PostPilot publishes your scheduled posts even when your '
                'phone is off. Notifications tell you how it went.',
                style: textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const _Benefit(
                icon: Icons.check_circle_rounded,
                text: 'Your post, Reel or Story is live',
              ),
              const _Benefit(
                icon: Icons.error_rounded,
                text: 'Something failed and needs a look',
              ),
              const Spacer(flex: 2),
              CustomButton(
                text: 'Turn on notifications',
                icon: Icons.notifications_rounded,
                isLoading: asking.value,
                onPressed: allow,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: asking.value ? null : () => navigation.pop(),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: context.textTheme.titleSmall)),
          ],
        ),
      ),
    );
  }
}
